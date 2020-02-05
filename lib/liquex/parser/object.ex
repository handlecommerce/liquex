defmodule Liquex.Parser.Object do
  import NimbleParsec

  alias Liquex.Parser.Literal
  alias Liquex.Parser.Field

  @spec argument(NimbleParsec.t()) :: NimbleParsec.t()
  def argument(combinator \\ empty()) do
    combinator
    |> choice([Literal.literal(), Field.field()])
  end

  @spec arguments(NimbleParsec.t()) :: NimbleParsec.t()
  def arguments(combinator \\ empty()) do
    combinator
    |> argument()
    |> repeat(
      ignore(Literal.whitespace())
      |> ignore(string(","))
      |> ignore(Literal.whitespace())
      |> concat(argument())
    )
  end

  @spec filter(NimbleParsec.t()) :: NimbleParsec.t()
  def filter(combinator \\ empty()) do
    combinator
    |> ignore(Literal.whitespace())
    |> ignore(utf8_char([?|]))
    |> ignore(Literal.whitespace())
    |> concat(Field.identifier())
    |> tag(
      optional(
        ignore(string(":"))
        |> ignore(Literal.whitespace())
        |> concat(arguments())
      ),
      :arguments
    )
    |> tag(:filter)
  end

  @spec object(NimbleParsec.t()) :: NimbleParsec.t()
  def object(combinator \\ empty()) do
    combinator
    |> ignore(string("{{"))
    |> ignore(Literal.whitespace())
    |> argument()
    |> optional(tag(repeat(filter()), :filters))
    |> ignore(Literal.whitespace())
    |> ignore(string("}}"))
    |> tag(:object)
  end
end
