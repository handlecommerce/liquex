defmodule Liquex.Cache.DisabledCache do
  @moduledoc """
  Default caching system for Liquex. Always runs the given function and never
  stores the results.
  """
  @behaviour Liquex.Cache

  @impl true
  def fetch(_key, func), do: func.()
end
