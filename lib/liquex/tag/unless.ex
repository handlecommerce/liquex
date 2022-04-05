defmodule Liquex.Tag.Unless do
  @behaviour Liquex.Tag
  import NimbleParsec

  alias Liquex.Expression
  alias Liquex.Parser.Tag
  alias Liquex.Parser.Tag.ControlFlow

  alias Liquex.Tag.If

  def parse do
    ControlFlow.expression_tag("unless")
    |> tag(parsec(:document), :contents)
    |> repeat(If.elsif_tag())
    |> optional(If.else_tag())
    |> ignore(Tag.tag_directive("endunless"))
  end

  def render([{:expression, expression}, {:contents, contents} | tail], context) do
    unless Expression.eval(expression, context) do
      Liquex.render(contents, context)
    else
      If.render(tail, context)
    end
  end
end
