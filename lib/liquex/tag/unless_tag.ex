defmodule Liquex.Tag.UnlessTag do
  @moduledoc """
  The opposite of if – executes a block of code only if a certain condition is
  not met.

  ### Input

      {% unless product.title == "Awesome Shoes" %}
        These shoes are not awesome.
      {% endunless %}

  ### Output

      These shoes are not awesome.

  This would be the equivalent of doing the following:

      {% if product.title != "Awesome Shoes" %}
        These shoes are not awesome.
      {% endif %}
  """

  @behaviour Liquex.Tag
  import NimbleParsec

  alias Liquex.Expression
  alias Liquex.Parser.Tag
  alias Liquex.Render

  alias Liquex.Tag.IfTag

  def parse do
    Tag.expression_tag("unless")
    |> tag(parsec(:document), :contents)
    |> repeat(IfTag.elsif_tag())
    |> optional(IfTag.else_tag())
    |> ignore(Tag.tag_directive("endunless"))
  end

  def render([{:expression, expression}, {:contents, contents} | tail], context) do
    if Expression.eval(expression, context) do
      IfTag.render(tail, context)
    else
      Render.render(contents, context)
    end
  end
end
