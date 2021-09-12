defmodule Liquex.Parser.Field do
  @moduledoc false

  import NimbleParsec

  alias Liquex.Parser.Literal
  alias Liquex.Parser.LiteralHelper

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
    |> parsec({LiteralHelper, :argument})
    |> ignore(Literal.whitespace())
    |> ignore(string("]"))
    |> unwrap_and_tag(:accessor)
  end

  @spec key_access(NimbleParsec.t()) :: NimbleParsec.t()
  def key_access(combinator \\ empty()) do
    combinator
    |> ignore(string("."))
    |> identifier()
    |> unwrap_and_tag(:key)
end

  @spec field(NimbleParsec.t()) :: NimbleParsec.t()
  def field(combinator \\ empty()) do
    combinator
    |> identifier()
    |> unwrap_and_tag(:key)
    |> repeat(choice([
      accessor(),
      key_access()
    ]))
    |> tag(:field)
  end

end
