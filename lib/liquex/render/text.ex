defmodule Liquex.Render.Text do
  @moduledoc false

  @behaviour Liquex.Render

  @type text_t :: {:text, iodata}

  @impl Liquex.Render
  def render({:text, text}, context), do: {text, context}
  def render(_, _), do: false
end
