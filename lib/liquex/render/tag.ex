defmodule Liquex.Render.Tag do
  @moduledoc false

  @behaviour Liquex.Render

  @impl Liquex.Render
  def render({{:custom_tag, module}, contents}, context) when is_atom(module),
    do: module.render(contents, context)

  def render(_, _), do: false
end
