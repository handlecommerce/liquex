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

  @impl true
  def parse do
    Tag.expression_tag("unless")
    |> tag(parsec(:document), :contents)
    |> repeat(IfTag.elsif_tag())
    |> optional(IfTag.else_tag())
    |> ignore(Tag.tag_directive("endunless"))
  end

  @impl true
  def parse_liquid_tag do
    Tag.liquid_tag_expression("unless")
    |> tag(parsec(:liquid_tag_contents), :contents)
    |> repeat(
      Tag.liquid_tag_expression("elsif")
      |> tag(parsec(:liquid_tag_contents), :contents)
      |> tag(:elsif)
    )
    |> optional(
      ignore(Tag.liquid_tag_directive("else"))
      |> tag(parsec(:liquid_tag_contents), :contents)
      |> tag(:else)
    )
    |> ignore(Tag.liquid_tag_directive("endunless"))
  end

  @impl true
  def render([{:expression, expression}, {:contents, contents} | tail], context) do
    {evaluated, context} = Expression.eval(expression, context)

    if evaluated do
      IfTag.render(tail, context)
    else
      Render.render!(contents, context)
    end
  end
end
