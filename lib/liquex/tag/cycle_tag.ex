defmodule Liquex.Tag.CycleTag do
  @moduledoc false

  @behaviour Liquex.Tag

  alias Liquex.Context
  alias Liquex.Parser.Argument
  alias Liquex.Parser.Literal
  alias Liquex.Parser.Tag

  import NimbleParsec

  def parse do
    cycle_group =
      Literal.literal()
      |> ignore(string(":"))
      |> ignore(Literal.whitespace())

    ignore(Tag.open_tag())
    |> ignore(string("cycle"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> optional(unwrap_and_tag(cycle_group, :group))
    |> tag(argument_sequence(), :sequence)
    |> ignore(Tag.close_tag())
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

  def render([], context), do: {[], context}

  def render([sequence: sequence], %Context{} = context),
    do: render([group: sequence, sequence: sequence], context)

  def render([group: group, sequence: sequence], %Context{cycles: cycles} = context) do
    index = Map.get(cycles, group, 0)

    next_index = rem(index + 1, length(sequence))

    result =
      sequence
      |> Enum.at(index)
      |> Liquex.Argument.eval(context)

    {result, %{context | cycles: Map.put(cycles, group, next_index)}}
  end
end
