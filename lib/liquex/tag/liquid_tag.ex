defmodule Liquex.Tag.LiquidTag do
  @moduledoc """

  ## liquid

  Encloses multiple tags within one set of delimiters, to allow writing Liquid
  logic more concisely.

      {% liquid
      case section.blocks.size
      when 1
        assign column_size = ''
      when 2
        assign column_size = 'one-half'
      when 3
        assign column_size = 'one-third'
      else
        assign column_size = 'one-quarter'
      endcase %}

  Because any tag blocks opened within a liquid tag must also be closed within
  the same tag, use echo to output data.
  """

  @behaviour Liquex.Tag
  import NimbleParsec

  alias Liquex.Context

  alias Liquex.Parser.Literal
  alias Liquex.Parser.Tag

  alias Liquex.Render

  @impl true
  @spec parse :: NimbleParsec.t()
  def parse do
    Tag.open_tag()
    |> string("liquid")
    |> Literal.whitespace(1)
    |> ignore()
    |> tag(parsec(:liquid_tag_contents), :contents)
    |> ignore(Literal.whitespace())
    |> ignore(Tag.close_tag())
  end

  @impl true
  @spec render(list, Liquex.Context.t()) :: Render.result_t()
  def render([contents: contents], %Context{} = context), do: Render.render!(contents, context)
end
