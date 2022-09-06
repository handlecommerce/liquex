defmodule Liquex.Parser do
  @moduledoc """
  Liquid parser
  """

  import NimbleParsec

  defmacro __using__(opts \\ []) do
    tags = Keyword.get(opts, :tags, [])

    quote location: :keep do
      import NimbleParsec

      custom_tags = Enum.map(unquote(tags), &tag(&1.parse(), {:tag, &1}))

      tags =
        [
          Liquex.Tag.AssignTag,
          Liquex.Tag.BreakTag,
          Liquex.Tag.CaptureTag,
          Liquex.Tag.CaseTag,
          Liquex.Tag.CommentTag,
          Liquex.Tag.ContinueTag,
          Liquex.Tag.CycleTag,
          Liquex.Tag.ForTag,
          Liquex.Tag.IfTag,
          Liquex.Tag.IncrementTag,
          Liquex.Tag.ObjectTag,
          Liquex.Tag.RawTag,
          Liquex.Tag.RenderTag,
          Liquex.Tag.TablerowTag,
          Liquex.Tag.UnlessTag
        ]
        |> Enum.map(&tag(&1.parse(), {:tag, &1}))

      # Special case for leading spaces before `{%-` and `{{-`
      leading_whitespace =
        empty()
        # credo:disable-for-lines:1
        |> Liquex.Parser.Literal.whitespace(1)
        |> lookahead(choice([string("{%-"), string("{{-")]))
        |> ignore()

      base =
        choice(
          custom_tags ++
            tags ++
            [
              # credo:disable-for-lines:2
              Liquex.Parser.Literal.text(),
              leading_whitespace
            ]
        )

      defcombinatorp(:document, repeat(base))
      defparsec(:parse, parsec(:document) |> eos())
    end
  end
end
