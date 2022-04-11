defmodule Liquex.Tag.ContinueTag do
  @moduledoc false

  @behaviour Liquex.Tag

  alias Liquex.Parser.Tag

  import NimbleParsec

  @impl true
  def parse do
    ignore(Tag.tag_directive("continue"))
  end

  @impl true
  def render(_, context), do: {:continue, [], context}
end
