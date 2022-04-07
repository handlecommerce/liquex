defmodule Liquex.Tag.CommentTag do
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
