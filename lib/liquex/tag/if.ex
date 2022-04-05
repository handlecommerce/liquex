defmodule Liquex.Tag.If do
  @behaviour Liquex.Tag
  import NimbleParsec

  alias Liquex.Expression
  alias Liquex.Parser.Tag
  alias Liquex.Parser.Tag.ControlFlow

  # alias Liquex.Context

  def parse do
    ControlFlow.expression_tag("if")
    |> tag(parsec(:document), :contents)
    |> repeat(elsif_tag())
    |> optional(else_tag())
    |> ignore(Tag.tag_directive("endif"))
  end

  @spec else_tag :: NimbleParsec.t()
  def else_tag do
    ignore(Tag.tag_directive("else"))
    |> tag(parsec(:document), :contents)
    |> tag(:else)
  end

  defp elsif_tag do
    ControlFlow.expression_tag("elsif")
    |> tag(parsec(:document), :contents)
    |> tag(:elsif)
  end

  def render([{:expression, expression}, {:contents, contents} | tail], context) do
    if Expression.eval(expression, context) do
      Liquex.render(contents, context)
    else
      do_render(tail, context)
    end
  end

  defp do_render([{:elsif, [expression: expression, contents: contents]} | tail], context) do
    if Expression.eval(expression, context) do
      Liquex.render(contents, context)
    else
      do_render(tail, context)
    end
  end

  defp do_render([else: [contents: contents]], context), do: Liquex.render(contents, context)
  defp do_render([], context), do: {[], context}
end
