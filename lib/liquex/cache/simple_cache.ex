defmodule Liquex.Cache.SimpleCache do
  @moduledoc """
  Basic caching system that uses ETS.
  """
  @behaviour Liquex.Cache

  @ets_table_name :liquex_simple_cache_table

  @spec init :: :ok
  def init do
    unless :ets.whereis(@ets_table_name) == :undefined, do: :ets.delete(@ets_table_name)
    :ets.new(@ets_table_name, [:named_table, :set, :private])
    :ok
  end

  @impl true
  def fetch(key, func) do
    case get(key) do
      :not_found -> set(key, func.())
      {:found, result} -> result
    end
  end

  defp get(key) do
    case :ets.lookup(@ets_table_name, key) do
      [] -> :not_found
      [{_key, result}] -> {:found, result}
    end
  end

  defp set(key, value) do
    true = :ets.insert(@ets_table_name, {key, value})

    value
  end
end
