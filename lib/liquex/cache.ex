defmodule Liquex.Cache do
  @moduledoc """
  Caching behaviour attached to a `Liquex.Context`.

  Currently, caching is only used for partial loading in render tags.
  """
  @type key :: any
  @type value :: any

  @doc """
  Fetch a value from cache. If the value doesn't exist, run the given function
  and store the results within the cache.
  """
  @callback fetch(key, (-> value())) :: value()
end
