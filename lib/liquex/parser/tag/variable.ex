defmodule Liquex.Parser.Tag.Variable do
  import NimbleParsec

  alias Liquex.Parser.Field
  alias Liquex.Parser.Literal

  def assign_tag(combinator \\ empty()) do
    combinator
    |> ignore(string("{%"))
    |> ignore(Literal.whitespace())
    |> ignore(string("assign"))
    |> ignore(Literal.whitespace())
    |> unwrap_and_tag(Field.identifier(), :left)
    |> ignore(Literal.whitespace())
    |> ignore(string("="))
    |> ignore(Literal.whitespace())
    |> tag(Literal.argument(), :right)
    |> ignore(Literal.whitespace())
    |> ignore(string("%}"))
    |> tag(:assign)
  end

  def capture_tag(combinator \\ empty()) do
    combinator
    |> ignore(string("{%"))
    |> ignore(Literal.whitespace())
    |> ignore(string("capture"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> unwrap_and_tag(Field.identifier(), :identifier)
    |> ignore(Literal.whitespace())
    |> ignore(string("%}"))
    |> tag(parsec(:document), :contents)
    |> ignore(string("{%"))
    |> ignore(Literal.whitespace())
    |> ignore(string("endcapture"))
    |> ignore(Literal.whitespace())
    |> ignore(string("%}"))
    |> tag(:capture)
  end

  def incrementer_tag(combinator \\ empty()) do
    increment = replace(string("increment"), 1)
    decrement = replace(string("decrement"), -1)

    combinator
    |> ignore(string("{%"))
    |> ignore(Literal.whitespace())
    |> unwrap_and_tag(choice([increment, decrement]), :by)
    |> ignore(Literal.whitespace(empty(), 1))
    |> unwrap_and_tag(Field.identifier(), :identifier)
    |> ignore(Literal.whitespace())
    |> ignore(string("%}"))
    |> post_traverse({__MODULE__, :reverse_tags, []})
    |> tag(:increment)
  end

  def reverse_tags(_rest, args, context, _line, _offset),
    do: {args |> Enum.reverse(), context}
end
