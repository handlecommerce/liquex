defmodule Liquex.Parser.Tag.Assignment do
  import NimbleParsec

  alias Liquex.Parser.Field
  alias Liquex.Parser.Literal

  def assign_tag(combinator \\ empty()) do
    combinator
    |> ignore(string("{%"))
    |> ignore(Literal.whitespace())
    |> ignore(string("assign"))
    |> ignore(Literal.whitespace())
    |> concat(Field.field())
    |> ignore(Literal.whitespace())
    |> ignore(string("="))
    |> ignore(Literal.whitespace())
    |> concat(Literal.argument())
    |> ignore(Literal.whitespace())
    |> ignore(string("%}"))
    |> tag(:assign)
  end
end
