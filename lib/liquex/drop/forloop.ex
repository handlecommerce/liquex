defmodule Liquex.Drop.Forloop do
  @moduledoc false
  # Backs the `forloop` variable inside `{% for %}` blocks. Attributes are
  # derived from the struct fields on demand, matching Liquid's
  # `Liquid::ForloopDrop`.

  use Liquex.Drop, cacheable: false

  defstruct [:index, :length, :parentloop]

  defliquid index(drop, _ctx), do: drop.index + 1
  defliquid index0(drop, _ctx), do: drop.index
  defliquid rindex(drop, _ctx), do: drop.length - drop.index
  defliquid rindex0(drop, _ctx), do: drop.length - drop.index - 1
  defliquid first(drop, _ctx), do: drop.index == 0
  defliquid last(drop, _ctx), do: drop.index == drop.length - 1
  defliquid length(drop, _ctx), do: drop.length
  defliquid parentloop(drop, _ctx), do: drop.parentloop
end
