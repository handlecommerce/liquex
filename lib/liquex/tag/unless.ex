defmodule Liquex.Tag.Unless do
  @behaviour Liquex.Tag
  import NimbleParsec

  alias Liquex.Expression
  alias Liquex.Parser.Tag

  alias Liquex.Tag.If

  def parse do
    Tag.expression_tag("unless")
    |> tag(parsec(:document), :contents)
    |> repeat(If.elsif_tag())
    |> optional(If.else_tag())
    |> ignore(Tag.tag_directive("endunless"))
  end

  def render([{:expression, expression}, {:contents, contents} | tail], context) do
    if Expression.eval(expression, context) do
      If.render(tail, context)
    else
      Liquex.render(contents, context)
    end
  end
end
