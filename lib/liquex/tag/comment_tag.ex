defmodule Liquex.Tag.CommentTag do
  @moduledoc """
  Allows you to leave un-rendered code inside a Liquid template. Any text within
  the opening and closing comment blocks will not be printed, and any Liquid
  code within will not be executed.

  ### Input

      {% assign verb = "turned" %}
      {% comment %}
      {% assign verb = "converted" %}
      {% endcomment %}
      Anything you put between {% comment %} and {% endcomment %} tags
      is {{ verb }} into a comment.

  ### Output


      Anything you put between  tags
      is turned into a comment.
  """

  @behaviour Liquex.Tag

  alias Liquex.Parser.Tag
  alias Liquex.Parser.Literal
  import NimbleParsec

  @impl true
  # Parse {% comment %}...{% endcomment %}
  def parse do
    comment =
      Tag.tag_directive("comment")
      |> parsec(:document)
      |> Tag.tag_directive("endcomment")

    inline_comment =
      string("{%")
      |> optional(string("-"))
      |> utf8_string([?\s, ?\n, ?\r, ?\t], min: 0)
      |> Literal.inline_comment()
      |> Literal.whitespace()
      |> Tag.close_tag()

    choice([comment, inline_comment]) |> ignore()
  end

  @impl true
  def parse_liquid_tag do
    # Unsupported, so just try to match on anything so it fails
    string("USDFADSJFKAJDFJKASDF")
  end

  @impl true
  def render(_contents, context), do: {[], context}
end
