defmodule Liquex.Parser.Field do
  @moduledoc false

  import NimbleParsec

  alias Liquex.Parser.Literal

  @spec identifier(NimbleParsec.t()) :: NimbleParsec.t()
  def identifier(combinator \\ empty()) do
    # Identifiers can start with any letter or underscore.
    #   - The remaining characters can include digits
    #   - May end in a question mark (?)
    combinator
    |> utf8_string([?a..?z, ?A..?Z, ?_], 1)
    |> concat(utf8_string([?a..?z, ?A..?Z, ?0..?9, ?_], min: 0))
    |> concat(optional(string("?")))
    |> reduce({Enum, :join, []})
  end

  @spec accessor(NimbleParsec.t()) :: NimbleParsec.t()
  def accessor(combinator \\ empty()) do
    combinator
    |> ignore(string("["))
    |> ignore(Literal.whitespace())
    |> integer(min: 1)
    |> ignore(Literal.whitespace())
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
