defmodule Liquex.Parsers.Fields do
  import NimbleParsec

  alias Liquex.Parsers.Literals

  @spec identifier(NimbleParsec.t()) :: NimbleParsec.t()
  def identifier(combinator \\ empty()) do
    # Identifiers can start with any letter or underscore.
    #   - the remaining characters can include digits
    combinator
    |> utf8_string([?a..?z, ?A..?Z, ?_], 1)
    |> concat(utf8_string([?a..?z, ?A..?Z, ?0..?9, ?_], min: 0))
    |> reduce({Enum, :join, []})
  end

  @spec accessor(NimbleParsec.t()) :: NimbleParsec.t()
  def accessor(combinator \\ empty()) do
    combinator
    |> ignore(string("["))
    |> ignore(Literals.whitespace())
    |> integer(min: 1)
    |> ignore(Literals.whitespace())
    |> ignore(string("]"))
    |> unwrap_and_tag(:accessor)
  end

  @spec field(NimbleParsec.t()) :: NimbleParsec.t()
  def field(combinator \\ empty()) do
    combinator
    |> identifier()
    |> unwrap_and_tag(:key)
    |> optional(accessor())
    |> repeat(
      ignore(string("."))
      |> identifier()
      |> unwrap_and_tag(:key)
      |> optional(accessor())
    )
    |> tag(:field)
  end
end
