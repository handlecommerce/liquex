defmodule Liquex.Parser.Tag.Iteration do
  import NimbleParsec

  alias Liquex.Parser.Field
  alias Liquex.Parser.Literal
  alias Liquex.Parser.Tag
  alias Liquex.Parser.Tag.Conditional

  @spec for_expression(NimbleParsec.t()) :: NimbleParsec.t()
  def for_expression(combinator \\ empty()) do
    combinator
    |> for_in_tag()
    |> tag(parsec(:document), :contents)
    |> tag(:for)
    |> optional(Conditional.else_tag())
    |> ignore(Tag.tag_directive("endfor"))
  end

  defp for_in_tag(combinator) do
    combinator
    |> ignore(string("{%"))
    |> ignore(Literal.whitespace())
    |> ignore(string("for"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> tag(Field.identifier(), :identifier)
    |> ignore(Literal.whitespace(empty(), 1))
    |> ignore(string("in"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> tag(collection(), :collection)
    |> ignore(Literal.whitespace())
    |> ignore(string("%}"))
  end

  defp collection(combinator \\ empty()) do
    combinator
    |> choice([Literal.range(), Literal.argument()])
  end
end
