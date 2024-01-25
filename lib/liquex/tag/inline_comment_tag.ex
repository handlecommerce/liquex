defmodule Liquex.Tag.InlineCommentTag do
  @moduledoc """
  """

  @behaviour Liquex.Tag

  alias Liquex.Parser.Tag
  alias Liquex.Parser.Literal

  import NimbleParsec

  @impl true
  # Parse {% # comment %}
  def parse do
    Tag.open_tag()
    |> string("#")
    |> eventually(Tag.end_liquid_line())
    |> times(
      empty()
      |> Literal.whitespace()
      |> string("#")
      |> eventually(Tag.end_liquid_line()),
      min: 0
    )
    |> Tag.close_tag()
    |> ignore()
  end

  @impl true
  def parse_liquid_tag do
    string("#")
    |> times(
      lookahead_not(choice([string("-%}"), string("%}"), utf8_string([?\r, ?\n], 1)]))
      |> utf8_char([]),
      min: 0
    )
    |> Tag.end_liquid_line()
    |> ignore()
  end

  @impl true
  def render(_contents, context), do: {[], context}
end
