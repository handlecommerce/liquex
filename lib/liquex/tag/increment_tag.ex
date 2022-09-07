defmodule Liquex.Tag.IncrementTag do
  @moduledoc false

  @behaviour Liquex.Tag
  import NimbleParsec

  alias Liquex.Context
  alias Liquex.Indifferent

  alias Liquex.Parser.Field
  alias Liquex.Parser.Literal
  alias Liquex.Parser.Tag

  def parse do
    increment = replace(string("increment"), 1)
    decrement = replace(string("decrement"), -1)

    ignore(Tag.open_tag())
    |> unwrap_and_tag(choice([increment, decrement]), :by)
    |> ignore(Literal.whitespace(empty(), 1))
    |> optional(unwrap_and_tag(Field.identifier(), :identifier))
    |> ignore(Tag.close_tag())
    |> post_traverse({__MODULE__, :reverse_tags, []})
  end

  def reverse_tags(_rest, args, context, _line, _offset),
    do: {args |> Enum.reverse(), context}

  def render(
        [identifier: identifier, by: increment],
        %Context{environment: environment} = context
      ) do
    default_value = if increment == -1, do: -1, else: 0

    {value, environment} =
      Indifferent.get_and_update(
        environment,
        identifier,
        fn
          nil -> {default_value, default_value + increment}
          v -> {v, v + increment}
        end
      )

    {[Integer.to_string(value)], %{context | environment: environment}}
  end

  # Handle default identifier (nil)
  def render([by: increment], context), do: render([identifier: nil, by: increment], context)
end
