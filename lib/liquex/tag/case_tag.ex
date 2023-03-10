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

  def parse_liquid_tag do
    case_contents()
    |> ignore(Tag.end_liquid_line())
    |> times(
      tag(
        when_contents()
        |> ignore(Tag.end_liquid_line())
        |> tag(parsec(:liquid_tag_contents), :contents),
        :when
      ),
      min: 1
    )
    |> optional(
      else_contents(empty())
      |> ignore(Tag.end_liquid_line())
      |> tag(parsec(:liquid_tag_contents), :contents)
      |> tag(:else)
    )
    |> ignore(Literal.whitespace())
    |> ignore(string("endcase"))
    |> ignore(Tag.end_liquid_line())
  end

  defp case_tag do
    ignore(Tag.open_tag())
    |> case_contents()
    |> ignore(Tag.close_tag())
  end

  defp case_contents(combinator \\ empty()) do
    combinator
    |> ignore(string("case"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> concat(Parser.Argument.argument())
  end

  defp when_tag do
    ignore(Tag.open_tag())
    |> when_contents()
    |> ignore(Tag.close_tag())
    |> tag(parsec(:document), :contents)
  end

  defp when_contents(combinator \\ empty()) do
    combinator
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
  end

  def else_tag do
    ignore(Tag.open_tag())
    |> else_contents()
    |> ignore(Tag.close_tag())
    |> tag(parsec(:document), :contents)
    |> tag(:else)
  end

  defp else_contents(combinator) do
    combinator
    |> ignore(string("else"))
  end

  @spec render(list, Liquex.Context.t()) :: Render.result_t()
  def render([argument | tail], context) do
    match = Argument.eval(argument, context)
    do_render(tail, context, match)
  end

  defp do_render([{:when, [expression: expressions, contents: contents]} | tail], context, match) do
    result = Enum.any?(expressions, &(match == Argument.eval(&1, context)))

    if result do
      Render.render!(contents, context)
    else
      do_render(tail, context, match)
    end
  end

  defp do_render([{:else, [contents: contents]} | _tail], context, _),
    do: Render.render!(contents, context)

  defp do_render([], context, _), do: {[], context}
end
