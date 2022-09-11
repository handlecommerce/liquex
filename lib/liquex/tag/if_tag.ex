defmodule Liquex.Tag.IfTag do
  @moduledoc """
  Executes a block of code only if a certain condition is true.

  ### Input

      {% if product.title == "Awesome Shoes" %}
        These shoes are awesome!
      {% endif %}

  ### Output

      These shoes are awesome!
  """

  @behaviour Liquex.Tag
  import NimbleParsec

  alias Liquex.Expression
  alias Liquex.Parser.Tag

  def parse do
    Tag.expression_tag("if")
    |> tag(parsec(:document), :contents)
    |> repeat(elsif_tag())
    |> optional(else_tag())
    |> ignore(Tag.tag_directive("endif"))
  end

  def elsif_tag do
    Tag.expression_tag("elsif")
    |> tag(parsec(:document), :contents)
    |> tag(:elsif)
  end

  def else_tag do
    ignore(Tag.tag_directive("else"))
    |> tag(parsec(:document), :contents)
    |> tag(:else)
  end

  def render([{:expression, expression}, {:contents, contents} | tail], context) do
    if Expression.eval(expression, context) do
      Liquex.Render.render(contents, context)
    else
      render(tail, context)
    end
  end

  def render([{:elsif, [expression: expression, contents: contents]} | tail], context) do
    if Expression.eval(expression, context) do
      Liquex.Render.render(contents, context)
    else
      render(tail, context)
    end
  end

  def render([else: [contents: contents]], context), do: Liquex.Render.render(contents, context)
  def render([], context), do: {[], context}
end
