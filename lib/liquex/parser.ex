defmodule Liquex.Parser do
  @moduledoc """
  Liquid parser
  """

  import NimbleParsec

  defmacro __using__(opts \\ []) do
    tags = Keyword.get(opts, :tags, [])

    quote location: :keep do
      import NimbleParsec

      custom_tags = Enum.map(unquote(tags), &tag(&1.parse(), {:custom_tag, &1}))

      base =
        choice(
          custom_tags ++
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
