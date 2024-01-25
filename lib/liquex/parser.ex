defmodule Liquex.Parser do
  @moduledoc """
  Liquid parser
  """

  import NimbleParsec

  defmacro __using__(opts \\ []) do
    tags = Keyword.get(opts, :tags, [])

    quote location: :keep do
      import NimbleParsec

      custom_tags = unquote(tags)

      tags =
        custom_tags ++
          [
            Liquex.Tag.AssignTag,
            Liquex.Tag.BreakTag,
            Liquex.Tag.CaptureTag,
            Liquex.Tag.CaseTag,
            Liquex.Tag.CommentTag,
            Liquex.Tag.ContinueTag,
            Liquex.Tag.CycleTag,
            Liquex.Tag.EchoTag,
            Liquex.Tag.ForTag,
            Liquex.Tag.IfTag,
            Liquex.Tag.IncrementTag,
            Liquex.Tag.InlineCommentTag,
            Liquex.Tag.LiquidTag,
            Liquex.Tag.ObjectTag,
            Liquex.Tag.RawTag,
            Liquex.Tag.RenderTag,
            Liquex.Tag.TablerowTag,
            Liquex.Tag.UnlessTag
          ]

      tags_parser = Enum.map(tags, &tag(&1.parse(), {:tag, &1}))

      # Ensure the tags are loaded into scope, otherwise function_exported? will
      # return false
      Enum.each(tags, &Code.ensure_loaded!/1)

      liquid_tags_parser =
        tags
        |> Enum.filter(&function_exported?(&1, :parse_liquid_tag, 0))
        |> Enum.map(&tag(&1.parse_liquid_tag(), {:tag, &1}))
        |> choice()

      # Special case for leading spaces before `{%-` and `{{-`
      leading_whitespace =
        empty()
        # credo:disable-for-lines:1
        |> Liquex.Parser.Literal.whitespace(1)
        |> lookahead(choice([string("{%-"), string("{{-")]))
        |> ignore()

      base =
        choice(
          tags_parser ++
            [
              # credo:disable-for-lines:2
              Liquex.Parser.Literal.text(),
              leading_whitespace
            ]
        )

      defcombinatorp(:document, repeat(base))
      defcombinatorp(:liquid_tag_contents, repeat(liquid_tags_parser))

      defparsec(:parse, parsec(:document) |> eos())
    end
  end
end
