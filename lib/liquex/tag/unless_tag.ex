defmodule Liquex.Tag.UnlessTag do
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
