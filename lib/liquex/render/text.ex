defmodule Liquex.Render.Text do
  def render({:text, text}, context), do: {text, context}
  def render(_, _), do: false
end
