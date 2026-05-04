defmodule Liquex.Drop.TablerowLoop do
  @moduledoc false
  # Backs the `tablerowloop` variable inside `{% tablerow %}` blocks.
  # Mirrors Liquid's `Liquid::TablerowloopDrop`.

  use Liquex.Drop, cacheable: false

  defstruct [:index, :length, :cols]

  defliquid length(drop, _ctx), do: drop.length
  defliquid index(drop, _ctx), do: drop.index + 1
  defliquid index0(drop, _ctx), do: drop.index
  defliquid rindex(drop, _ctx), do: drop.length - drop.index
  defliquid rindex0(drop, _ctx), do: drop.length - drop.index - 1
  defliquid col(drop, _ctx), do: rem(drop.index, drop.cols) + 1
  defliquid col0(drop, _ctx), do: rem(drop.index, drop.cols)
  defliquid row(drop, _ctx), do: div(drop.index, drop.cols) + 1
  defliquid first(drop, _ctx), do: drop.index == 0
  defliquid last(drop, _ctx), do: drop.index == drop.length - 1
  defliquid col_first(drop, _ctx), do: rem(drop.index, drop.cols) == 0
  defliquid col_last(drop, _ctx), do: rem(drop.index, drop.cols) == drop.cols - 1
end
