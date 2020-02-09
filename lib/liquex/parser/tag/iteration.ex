defmodule Liquex.Parser.Tag.Iteration do
  import NimbleParsec

  alias Liquex.Parser.Field
  alias Liquex.Parser.Literal
  alias Liquex.Parser.Tag
  alias Liquex.Parser.Tag.ControlFlow

  @spec for_expression(NimbleParsec.t()) :: NimbleParsec.t()
  def for_expression(combinator \\ empty()) do
    combinator
    |> for_in_tag()
    |> tag(parsec(:document), :contents)
    |> tag(:for)
    |> optional(ControlFlow.else_tag())
    |> ignore(Tag.tag_directive("endfor"))
  end

  @spec cycle_tag(NimbleParsec.t()) :: NimbleParsec.t()
  def cycle_tag(combinator \\ empty()) do
    combinator
    |> ignore(string("{%"))
    |> ignore(Literal.whitespace())
    |> ignore(string("cycle"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> optional(cycle_group() |> unwrap_and_tag(:group))
    |> tag(argument_sequence(), :sequence)
    |> ignore(Literal.whitespace())
    |> ignore(string("%}"))
    |> tag(:cycle)
  end

  @spec continue_tag(NimbleParsec.t()) :: NimbleParsec.t()
  def continue_tag(combinator \\ empty()) do
    combinator
    |> ignore(Tag.tag_directive("continue"))
    |> replace(:continue)
  end

  @spec break_tag(NimbleParsec.t()) :: NimbleParsec.t()
  def break_tag(combinator \\ empty()) do
    combinator
    |> ignore(Tag.tag_directive("break"))
    |> replace(:break)
  end

  defp argument_sequence(combinator \\ empty()) do
    combinator
    |> Literal.argument()
    |> repeat(
      ignore(string(","))
      |> ignore(Literal.whitespace())
      |> Literal.argument()
    )
  end

  defp for_in_tag(combinator) do
    combinator
    |> ignore(string("{%"))
    |> ignore(Literal.whitespace())
    |> ignore(string("for"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> unwrap_and_tag(Field.identifier(), :identifier)
    |> ignore(Literal.whitespace(empty(), 1))
    |> ignore(string("in"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> tag(collection(), :collection)
    |> ignore(Literal.whitespace())
    |> unwrap_and_tag(for_parameters(), :parameters)
    |> ignore(Literal.whitespace())
    |> ignore(string("%}"))
  end

  defp collection(combinator \\ empty()) do
    combinator
    |> choice([Literal.range(), Literal.argument()])
  end

  defp for_parameters(combinator \\ empty()) do
    combinator
    |> repeat(choice([reversed(), limit(), offset()]))
    |> reduce({Enum, :into, [%{}]})
  end

  defp reversed(combinator \\ empty()) do
    combinator
    |> replace(string("reversed"), :reversed)
    |> unwrap_and_tag(:order)
    |> ignore(Literal.whitespace())
  end

  defp limit(combinator \\ empty()) do
    combinator
    |> ignore(string("limit:"))
    |> unwrap_and_tag(integer(min: 1), :limit)
    |> ignore(Literal.whitespace())
  end

  defp offset(combinator \\ empty()) do
    combinator
    |> ignore(string("offset:"))
    |> unwrap_and_tag(integer(min: 1), :offset)
    |> ignore(Literal.whitespace())
  end

  defp cycle_group(combinator \\ empty()) do
    combinator
    |> Literal.literal()
    |> ignore(string(":"))
    |> ignore(Literal.whitespace())
  end
end
