defmodule Liquex.Tag.LiquidTag do
  @moduledoc """

  """

  @behaviour Liquex.Tag
  import NimbleParsec

  alias Liquex.Context

  alias Liquex.Parser.Tag
  alias Liquex.Parser.Literal

  alias Liquex.Render

  @impl true
  def parse do
    Tag.open_tag()
    |> string("liquid")
    |> Literal.whitespace(1)
    |> ignore()
    |> tag(parsec(:liquid_tag_contents), :contents)
    |> ignore(Literal.whitespace(empty(), 0))
    |> ignore(Tag.close_tag())
  end

  @impl true
  def render([contents: contents], %Context{} = context) do
    Render.render(contents, context)
  end
end
