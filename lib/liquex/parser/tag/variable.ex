defmodule Liquex.Parser.Tag.Variable do
  @moduledoc false

  import NimbleParsec

  alias Liquex.Parser.Field
  alias Liquex.Parser.Literal
  alias Liquex.Parser.Object
  alias Liquex.Parser.Tag

  def assign_tag(combinator \\ empty()) do
    literal_and_filters =
      empty()
      |> Literal.argument()
      |> optional(tag(repeat(Object.filter()), :filters))

    combinator
    |> ignore(Tag.open_tag())
    |> ignore(string("assign"))
    |> ignore(Literal.whitespace())
    |> unwrap_and_tag(Field.identifier(), :left)
    |> ignore(Literal.whitespace())
    |> ignore(string("="))
    |> ignore(Literal.whitespace())
    |> tag(literal_and_filters, :right)
    |> ignore(Tag.close_tag())
    |> tag(:assign)
  end

  def capture_tag(combinator \\ empty()) do
    combinator
    |> ignore(Tag.open_tag())
    |> ignore(string("capture"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> unwrap_and_tag(Field.identifier(), :identifier)
    |> ignore(Tag.close_tag())
    |> tag(parsec(:document), :contents)
    |> ignore(Tag.tag_directive("endcapture"))
    |> tag(:capture)
  end

  def incrementer_tag(combinator \\ empty()) do
    increment = replace(string("increment"), 1)
    decrement = replace(string("decrement"), -1)

    combinator
    |> ignore(Tag.open_tag())
    |> unwrap_and_tag(choice([increment, decrement]), :by)
    |> ignore(Literal.whitespace(empty(), 1))
    |> unwrap_and_tag(Field.identifier(), :identifier)
    |> ignore(Tag.close_tag())
    |> post_traverse({__MODULE__, :reverse_tags, []})
    |> tag(:increment)
  end

  def reverse_tags(_rest, args, context, _line, _offset),
    do: {args |> Enum.reverse(), context}
end
