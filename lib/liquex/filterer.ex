defmodule Liquex.Filterer do
  @callback apply(any, {:filter, [...]}, map) :: any
end
