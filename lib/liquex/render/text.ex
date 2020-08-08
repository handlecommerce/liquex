defmodule Liquex.Render.Text do
  @moduledoc """
  Renderer for text blocks
  """
  @behaviour Liquex.Render

  @type text_t :: {:text, any}

  @impl Liquex.Render
  def render({:text, text}, context), do: {text, context}
  def render(_, _), do: false
end
