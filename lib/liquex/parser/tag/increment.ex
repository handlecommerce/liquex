defmodule Liquex.Parser.Tag.Increment do
  import NimbleParsec

  alias Liquex.Parser.Field
  alias Liquex.Parser.Literal

  def incrementer_tag(combinator \\ empty()) do
    increment = replace(string("increment"), 1)
    decrement = replace(string("decrement"), -1)

    combinator
    |> ignore(string("{%"))
    |> ignore(Literal.whitespace())
    |> unwrap_and_tag(choice([increment, decrement]), :by)
    |> ignore(Literal.whitespace(empty(), 1))
    |> concat(Field.field())
    |> ignore(Literal.whitespace())
    |> ignore(string("%}"))
    |> post_traverse({__MODULE__, :reverse_tags, []})
    |> tag(:increment)
  end

  def reverse_tags(_rest, args, context, _line, _offset),
    do: {args |> Enum.reverse(), context}
end
