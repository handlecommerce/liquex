defmodule Liquex.Parser.Tag.Iteration do
  @moduledoc false

  import NimbleParsec

  alias Liquex.Parser.Argument
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
    cycle_group =
      Literal.literal()
      |> ignore(string(":"))
      |> ignore(Literal.whitespace())

    combinator
    |> ignore(Tag.open_tag())
    |> ignore(string("cycle"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> optional(cycle_group |> unwrap_and_tag(:group))
    |> tag(argument_sequence(), :sequence)
    |> ignore(Tag.close_tag())
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

  def tablerow_tag(combinator \\ empty()) do
    tablerow_parameters = repeat(choice([cols(), limit(), offset()]))

    combinator
    |> ignore(Tag.open_tag())
    |> ignore(string("tablerow"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> unwrap_and_tag(Field.identifier(), :identifier)
    |> ignore(Literal.whitespace(empty(), 1))
    |> ignore(string("in"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> tag(collection(), :collection)
    |> ignore(Literal.whitespace())
    |> tag(tablerow_parameters, :parameters)
    |> ignore(Tag.close_tag())
    |> tag(parsec(:document), :contents)
    |> ignore(Tag.tag_directive("endtablerow"))
    |> tag(:tablerow)
  end

  defp argument_sequence(combinator \\ empty()) do
    combinator
    |> Argument.argument()
    |> repeat(
      ignore(string(","))
      |> ignore(Literal.whitespace())
      |> Argument.argument()
    )
  end

  defp for_in_tag(combinator) do
    combinator
    |> ignore(Tag.open_tag())
    |> ignore(string("for"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> unwrap_and_tag(Field.identifier(), :identifier)
    |> ignore(Literal.whitespace(empty(), 1))
    |> ignore(string("in"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> tag(collection(), :collection)
    |> ignore(Literal.whitespace())
    |> tag(for_parameters(), :parameters)
    |> ignore(Tag.close_tag())
  end

  defp collection do
    choice([Literal.range(), Argument.argument()])
  end

  defp for_parameters do
    reversed =
      replace(string("reversed"), :reversed)
      |> unwrap_and_tag(:order)
      |> ignore(Literal.whitespace())

    repeat(choice([reversed, limit(), offset()]))
  end

  defp cols do
    ignore(string("cols:"))
    |> ignore(Literal.whitespace())
    |> unwrap_and_tag(integer(min: 1), :cols)
    |> ignore(Literal.whitespace())
  end

  defp limit do
    ignore(string("limit:"))
    |> ignore(Literal.whitespace())
    |> unwrap_and_tag(integer(min: 1), :limit)
    |> ignore(Literal.whitespace())
  end

  defp offset do
    ignore(string("offset:"))
    |> ignore(Literal.whitespace())
    |> choice([
      replace(string("continue"), :continue)
      |> unwrap_and_tag(:offset),
      unwrap_and_tag(integer(min: 1), :offset)
    ])
    |> ignore(Literal.whitespace())
  end
end
