defmodule Liquex.Tag.EchoTag do
  @moduledoc """
  Outputs an expression in the rendered HTML. This is identical to wrapping an
  expression in {{ and }}, but works inside liquid tags and supports filters.

  ### Input

      {% liquid
      for product in collection.products
        echo product.title | capitalize
      endfor %}

  ### Output

      Hat Shirt Pants
  """

  @behaviour Liquex.Tag
  import NimbleParsec

  alias Liquex.Context

  alias Liquex.Parser.Tag
  alias Liquex.Parser.Argument
  alias Liquex.Tag.ObjectTag
  alias Liquex.Parser.Literal

  alias Liquex.Render

  @impl true
  def parse do
    ignore(Tag.open_tag())
    |> ignore(string("echo"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> Argument.argument()
    |> optional(ObjectTag.filters())
    |> ignore(Literal.whitespace())
    |> ignore(Tag.close_tag())
  end

  @impl true
  def parse_liquid_tag do
    ignore(string("echo"))
    |> echo_contents()
  end

  defp echo_contents(combinator) do
    combinator
    |> ignore(Literal.whitespace(empty(), 1))
    |> Argument.argument()
    |> optional(ObjectTag.filters())
  end

  @impl true
  def render([argument, filters: filters], %Context{} = context) do
    {result, context} =
      argument
      |> List.wrap()
      |> Liquex.Argument.eval(context)
      |> Render.apply_filters(filters, context)

    {to_string(result), context}
  end
end
