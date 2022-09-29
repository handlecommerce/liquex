defmodule Liquex.Tag.CycleTag do
  @moduledoc """
  Loops through a group of strings and prints them in the order that they were
  passed as arguments. Each time cycle is called, the next string argument is
  printed.

  cycle must be used within a for loop block.

  ### Input

      {% cycle "one", "two", "three" %}
      {% cycle "one", "two", "three" %}
      {% cycle "one", "two", "three" %}
      {% cycle "one", "two", "three" %}

  ### Output

      one
      two
      three
      one

  Uses for cycle include:

    * applying odd/even classes to rows in a table
    * applying a unique class to the last product thumbnail in a row

  ## cycle (parameters)

  cycle accepts a “cycle group” parameter in cases where you need multiple cycle
  blocks in one template. If no name is supplied for the cycle group, then it is
  assumed that multiple calls with the same parameters are one group.

  ### Input

      {% cycle "first": "one", "two", "three" %}
      {% cycle "second": "one", "two", "three" %}
      {% cycle "second": "one", "two", "three" %}
      {% cycle "first": "one", "two", "three" %}

  ### Output

      one
      one
      two
      two
  """

  @behaviour Liquex.Tag

  alias Liquex.Context
  alias Liquex.Parser.Argument
  alias Liquex.Parser.Literal
  alias Liquex.Parser.Tag

  import NimbleParsec

  def parse do
    ignore(Tag.open_tag())
    |> do_parse_cycle()
    |> ignore(Tag.close_tag())
  end

  def parse_liquid_tag do
    do_parse_cycle()
    |> ignore(Tag.end_liquid_line())
  end

  def do_parse_cycle(combinator \\ empty()) do
    cycle_group =
      Literal.literal()
      |> ignore(string(":"))
      |> ignore(Literal.non_breaking_whitespace())

    combinator
    |> ignore(string("cycle"))
    |> ignore(Literal.non_breaking_whitespace(empty(), 1))
    |> optional(unwrap_and_tag(cycle_group, :group))
    |> tag(argument_sequence(), :sequence)
  end

  defp argument_sequence(combinator \\ empty()) do
    combinator
    |> Argument.argument()
    |> repeat(
      ignore(string(","))
      |> ignore(Literal.non_breaking_whitespace())
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
