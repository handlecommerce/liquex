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

  import NimbleParsec

  @impl true
  # Parse {% comment %}...{% endcomment %}
  def parse do
    ignore(Tag.tag_directive("comment"))
    |> ignore(parsec(:document))
    |> ignore(Tag.tag_directive("endcomment"))
  end

  @impl true
  def render(_contents, context), do: {[], context}
end
