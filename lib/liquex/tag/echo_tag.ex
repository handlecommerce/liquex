defmodule Liquex.Tag.EchoTag do
  @moduledoc """
  Objects contain the content that Liquid displays on a page. Objects and
  variables are displayed when enclosed in double curly braces: {{ and }}.

  ### Input

      {{ page.title }}

  ### Output

      Introduction

  In this case, Liquid is rendering the content of the title property of the
  page object, which contains the text Introduction.
  """

  @behaviour Liquex.Tag
  import NimbleParsec

  alias Liquex.Context

  alias Liquex.Parser.Tag
  alias Liquex.Parser.Argument
  alias Liquex.Tag.ObjectTag
  alias Liquex.Parser.Literal

  alias Liquex.Render

  def parse do
    ignore(Tag.open_tag())
    |> ignore(string("echo"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> Argument.argument()
    |> optional(ObjectTag.filters())
    |> ignore(Literal.whitespace())
    |> ignore(Tag.close_tag())
  end

  def render([argument, filters: filters], %Context{} = context) do
    {result, context} =
      argument
      |> List.wrap()
      |> Liquex.Argument.eval(context)
      |> Render.apply_filters(filters, context)

    {to_string(result), context}
  end
end
