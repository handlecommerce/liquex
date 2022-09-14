defmodule Liquex.Tag.CaseTag do
  @moduledoc """
  Creates a switch statement to execute a particular block of code when a
  variable has a specified value. case initializes the switch statement, and
  when statements define the various conditions.

  An optional else statement at the end of the case provides code to execute if
  none of the conditions are met.

  ### Input

      {% assign handle = "cake" %}
      {% case handle %}
        {% when "cake" %}
          This is a cake
        {% when "cookie", "biscuit" %}
          This is a cookie
        {% else %}
          This is not a cake nor a cookie
      {% endcase %}

  ### Output

      This is a cake
  """

  @behaviour Liquex.Tag
  import NimbleParsec

  alias Liquex.Argument
  alias Liquex.Parser
  alias Liquex.Parser.Literal
  alias Liquex.Parser.Tag
  alias Liquex.Render

  def parse do
    case_tag()
    |> ignore(Literal.whitespace())
    |> times(tag(when_tag(), :when), min: 1)
    |> optional(else_tag())
    |> ignore(Tag.tag_directive("endcase"))
  end

  defp case_tag do
    ignore(Tag.open_tag())
    |> ignore(string("case"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> concat(Parser.Argument.argument())
    |> ignore(Tag.close_tag())
  end

  defp when_tag do
    ignore(Tag.open_tag())
    |> ignore(string("when"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> tag(
      Literal.literal()
      |> repeat(
        ignore(string(","))
        |> ignore(Literal.whitespace(empty(), 1))
        |> Literal.literal()
      ),
      :expression
    )
    |> ignore(Tag.close_tag())
    |> tag(parsec(:document), :contents)
  end

  def else_tag do
    ignore(Tag.tag_directive("else"))
    |> tag(parsec(:document), :contents)
    |> tag(:else)
  end

  def render([argument | tail], context) do
    match = Argument.eval(argument, context)
    do_render(tail, context, match)
  end

  defp do_render([{:when, [expression: expressions, contents: contents]} | tail], context, match) do
    result = Enum.any?(expressions, &(match == Argument.eval(&1, context)))

    if result do
      Render.render(contents, context)
    else
      do_render(tail, context, match)
    end
  end

  defp do_render([{:else, [contents: contents]} | _tail], context, _),
    do: Render.render(contents, context)

  defp do_render([], context, _), do: {[], context}
end
