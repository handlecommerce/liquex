defmodule Liquex.Render.Text do
  @behaviour Liquex.Render

  @impl Liquex.Render
  def render({:text, text}, context), do: {text, context}
  def render(_, _), do: false
end
