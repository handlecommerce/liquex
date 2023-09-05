defmodule Liquex.Tag.AssignTag do
  @moduledoc """
  Creates a new named variable.

  ### Input

      {% assign my_variable = false %}
      {% if my_variable != true %}
        This statement is valid.
      {% endif %}

  ### Output

      This statement is valid.

  Wrap a value in quotations " to save it as a string variable.

  ### Input

      {% assign foo = "bar" %}
      {{ foo }}

  ### Output

      bar
  """

  @behaviour Liquex.Tag

  alias Liquex.Context
  alias Liquex.Parser.Argument
  alias Liquex.Parser.Field
  alias Liquex.Parser.Literal
  alias Liquex.Parser.Object
  alias Liquex.Parser.Tag

  alias Liquex.Render

  import NimbleParsec

  def parse do
    ignore(Tag.open_tag())
    |> assign_contents()
    |> ignore(Tag.close_tag())
  end

  def parse_liquid_tag do
    assign_contents()
    |> ignore(Tag.end_liquid_line())
  end

  def assign_contents(combinator \\ empty()) do
    literal_and_filters =
      Argument.argument()
      |> optional(tag(repeat(Object.filter()), :filters))

    combinator
    |> ignore(string("assign"))
    |> ignore(Literal.whitespace())
    |> unwrap_and_tag(Field.identifier(), :left)
    |> ignore(Literal.whitespace())
    |> ignore(string("="))
    |> ignore(Literal.whitespace())
    |> tag(literal_and_filters, :right)
  end

  def render([left: left, right: [right, filters: filters]], %Context{} = context)
      when is_binary(left) do
    {right, context} =
      right
      |> Liquex.Argument.eval(context)
      |> then(fn {value, context} -> Render.apply_filters(value, filters, context) end)

    context = Context.assign_global(context, left, right)

    {[], context}
  end
end
