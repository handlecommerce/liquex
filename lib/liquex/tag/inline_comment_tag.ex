defmodule Liquex.Tag.InlineCommentTag do
  @moduledoc """
  A tag that allows for inline comments using the # character.

  ## liquid
      Nothing in the comments will be rendered.
      {% # This is a comment and won't be rendered %}

      {% liquid # This is also a comment and won't be rendered %}


  ### Output
      Nothing in the comments will be rendered.


  """

  @behaviour Liquex.Tag

  alias Liquex.Parser.Literal
  alias Liquex.Parser.Tag

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
