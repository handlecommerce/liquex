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
          Liquex.Tag.Assign,
          Liquex.Tag.Capture,
          Liquex.Tag.Comment,
          Liquex.Tag.If,
          Liquex.Tag.Increment,
          Liquex.Tag.Raw
        ]
        |> Enum.map(&tag(&1.parse(), {:tag, &1}))

      base =
        choice(
          custom_tags ++
            tags ++
            [
              # credo:disable-for-lines:4
              Liquex.Parser.Object.object(),
              Liquex.Parser.Tag.tag(),
              Liquex.Parser.Literal.text(),
              Liquex.Parser.Literal.ignored_leading_whitespace()
            ]
        )

      defcombinatorp(:document, repeat(base))
      defparsec(:parse, parsec(:document) |> eos())
    end
  end
end
