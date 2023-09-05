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

  alias Liquex.Parser.Argument
  alias Liquex.Parser.Literal
  alias Liquex.Parser.Tag
  alias Liquex.Tag.ObjectTag

  alias Liquex.Render

  @impl true
  def parse do
    ignore(Tag.open_tag())
    |> echo_contents()
    |> ignore(Literal.whitespace())
    |> ignore(Tag.close_tag())
  end

  @impl true
  def parse_liquid_tag do
    echo_contents()
    |> ignore(Tag.end_liquid_line())
  end

  defp echo_contents(combinator \\ empty()) do
    combinator
    |> ignore(string("echo"))
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
      |> then(fn {value, context} -> Render.apply_filters(value, filters, context) end)

    {to_string(result), context}
  end
end
