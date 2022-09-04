defmodule Liquex.Tag.BreakTag do
  @moduledoc false

  @behaviour Liquex.Tag

  alias Liquex.Parser.Tag

  import NimbleParsec

  @impl true
  def parse do
    ignore(Tag.tag_directive("break"))
  end

  @impl true
  def render(_, context) do
    {:break, [], context}
  end
end
