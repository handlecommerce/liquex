defmodule Liquex.Cache do
  @moduledoc """
  Caching behaviour attached to a `Liquex.Context`.

  Used internally to memoize parsed partial templates. Custom filters can
  also opt in to per-render memoization via `memoize/3` — useful for
  wrapping calls to external systems (DB, HTTP, etc.) that are
  referentially transparent within a single render.

  Plug an implementation in via `Liquex.Context.new(env, cache: MyCache)`.
  Two implementations ship with Liquex:

    * `Liquex.Cache.DisabledCache` — default; never memoizes.
    * `Liquex.Cache.SimpleCache` — ETS-backed; call `init/0` before use.

  ## Example: a memoizing custom filter

      defmodule MyFilters do
        use Liquex.Filter

        def lookup(value, context) do
          Liquex.Cache.memoize(context, {__MODULE__, :lookup, value}, fn ->
            ExpensiveSystem.fetch(value)
          end)
        end
      end

      ctx =
        Liquex.Context.new(%{},
          cache: Liquex.Cache.SimpleCache,
          cache_prefix: tenant_id,
          filter_module: MyFilters
        )

  Drops cannot reach the context from `Access.fetch/2`, and custom
  `Liquex.FileSystem` modules see only a template name. Both have to hold
  their own cache reference if they need memoization. The built-in
  partial-template cache in `Liquex.Tag.RenderTag` already covers the
  read+parse path.
  """

  alias Liquex.Context

  @type key :: any
  @type value :: any

  @doc """
  Fetch a value from cache. If the value doesn't exist, run the given function
  and store the results within the cache.
  """
  @callback fetch(key, (-> value())) :: value()

  @doc """
  Memoize `fun` in `context`'s cache, namespaced by `context.cache_prefix`.

  Convenience over `context.cache.fetch/2`: pulls the cache module and
  prefix from the context, and tuples the prefix into the lookup key so two
  contexts sharing one `SimpleCache` table don't collide.

  When `cache:` is the default `Liquex.Cache.DisabledCache`, this just calls
  `fun.()` every time — extension authors can use `memoize/3` unconditionally.
  """
  @spec memoize(Context.t(), key(), (-> value())) :: value()
  def memoize(%Context{cache: cache, cache_prefix: prefix}, key, fun) do
    cache.fetch({prefix, key}, fun)
  end
end
