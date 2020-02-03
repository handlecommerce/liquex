defmodule Liquex.Parsers.Objects do
  import NimbleParsec

  alias Liquex.Parsers.Literals
  alias Liquex.Parsers.Fields

  def argument(combinator \\ empty()) do
    combinator
    |> choice([Literals.literal(), Fields.field()])
  end

  def arguments(combinator \\ empty()) do
    combinator
    |> argument()
    |> repeat(
      ignore(Literals.whitespace())
      |> ignore(string(","))
      |> ignore(Literals.whitespace())
      |> concat(argument())
    )
  end

  def filter(combinator \\ empty()) do
    combinator
    |> ignore(Literals.whitespace())
    |> ignore(utf8_char([?|]))
    |> ignore(Literals.whitespace())
    |> concat(Fields.identifier())
    |> tag(
      optional(
        ignore(string(":"))
        |> ignore(Literals.whitespace())
        |> concat(arguments())
      ),
      :arguments
    )
    |> tag(:filter)
  end

  def object(combinator \\ empty()) do
    combinator
    |> ignore(string("{{"))
    |> ignore(Literals.whitespace())
    |> argument()
    |> optional(tag(repeat(filter()), :filters))
    |> ignore(Literals.whitespace())
    |> ignore(string("}}"))
    |> tag(:object)
  end
end
