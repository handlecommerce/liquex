defmodule Liquex.Tag.IncrementTag do
  @moduledoc """

  ## increment

  Creates and outputs a new number variable with initial value 0. On subsequent
  calls, it increases its value by one and outputs the new value.

  ### Input

      {% increment my_counter %}
      {% increment my_counter %}
      {% increment my_counter %}

  ### Output

    0
    1
    2

  Variables created using increment are independent from variables created using
  assign or capture.

  In the example below, a variable named “var” is created using assign. The
  increment tag is then used several times on a variable with the same name.
  Note that the increment tag does not affect the value of “var” that was
  created using assign.

  ### Input

      {% assign var = 10 %}
      {% increment var %}
      {% increment var %}
      {% increment var %}
      {{ var }}

  ### Output

      0
      1
      2
      10

  ## decrement

  Creates and outputs a new number variable with initial value -1. On subsequent
  calls, it decreases its value by one and outputs the new value.

  ### Input

      {% decrement variable %}
      {% decrement variable %}
      {% decrement variable %}

  ### Output

      -1
      -2
      -3

  Like increment, variables declared using decrement are independent from
  variables created using assign or capture.
  """

  @behaviour Liquex.Tag
  import NimbleParsec

  alias Liquex.Context
  alias Liquex.Indifferent

  alias Liquex.Parser.Field
  alias Liquex.Parser.Literal
  alias Liquex.Parser.Tag

  def parse do
    # Replace as {default, increment}
    increment = replace(string("increment"), {0, 1})
    decrement = replace(string("decrement"), {-1, -1})

    ignore(Tag.open_tag())
    |> unwrap_and_tag(choice([increment, decrement]), :by)
    |> ignore(Literal.whitespace(empty(), 1))
    |> optional(unwrap_and_tag(Field.identifier(), :identifier))
    |> ignore(Tag.close_tag())
    |> post_traverse({__MODULE__, :reverse_tags, []})
  end

  def parse_liquid_tag do
    # Replace as {default, increment}
    increment = replace(string("increment"), {0, 1})
    decrement = replace(string("decrement"), {-1, -1})

    choice([increment, decrement])
    |> unwrap_and_tag(:by)
    |> ignore(Literal.non_breaking_whitespace(empty(), 0))
    |> optional(unwrap_and_tag(Field.identifier(), :identifier))
    |> ignore(Tag.end_liquid_line())
    |> post_traverse({__MODULE__, :reverse_tags, []})
  end

  def reverse_tags(_rest, args, context, _line, _offset),
    do: {args |> Enum.reverse(), context}

  def render(
        [identifier: identifier, by: {default, increment}],
        %Context{environment: environment} = context
      ) do
    {value, environment} =
      Indifferent.get_and_update(
        environment,
        identifier,
        fn
          nil -> {default, default + increment}
          v -> {v, v + increment}
        end
      )

    {[Integer.to_string(value)], %{context | environment: environment}}
  end

  # Handle default identifier (nil)
  def render([by: increment], context), do: render([identifier: nil, by: increment], context)
end
