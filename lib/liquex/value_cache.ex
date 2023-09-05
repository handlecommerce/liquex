defmodule Liquex.ValueCache do
  @moduledoc """
  A cache for storing lazy variables' execution results during rendering.

  The cache is not persisted between renders, and is intended to save on execution time
  during a single render. If you need to cache data between renders, we recommend handling
  that on the application level using Nebulex or another caching library.

  To use the cache, just define your lazy resolvers to accept two parameters, `parent`
  and `context`. The `context` will be accessed/updated by the cache functions in this
  module, so needs to be returned at the end of your resolver. Your resolver should return
  either `{value, context}` or just `value` if you made no changes to the context.

  Here's an example:

      import Liquex.ValueCache

      products_resolver = fn _parent, context ->
        IO.puts("fetching products")

        products = Product.all()
        {products, context |> cache_result(products)}
      end

      with {:ok, document} <- Liquex.parse("There are {{ products.size }} products, with {{ products.size }} available"),
          {result, _} <- Liquex.render!(document, %{products: products_resolver}) do
        result
      end

      "fetching products"
      "There are 5 products, with 5 products available"

  ## Result caching

  cache_result(context, value) replaces the lazy resolver in the context with the value
  of its execution, thus the function won't ever be called again.

  return_cached_result(context, value) is a helper function that returns the value and
  the updated context (with the cached value) automatically:

      import Liquex.ValueCache

      products_resolver = fn _parent, context ->
        return_cached_result(context, Product.all())
      end

  Note that you cannot cache a result if any of the parents of the current resolver are
  being preserved as functions (and not being replaced with result caching), as result
  caching replaces the lazy loader with the result of its execution, and it cannot do so
  if the parent is still a function.

  For this type of scenario (and others), you can use manual caching.

  ## Manual caching

  Sometimes, you may have a more complex scenario, where you want to keep the resolver
  function around but still cache the results of expensive calls from inside the resolver
  function. For this, we provide a manual cache:

      import Liquex.ValueCache

      products_resolver = fn _parent, context ->
        products = get_cache(context, :products)
        if products do
          {products, context}
        else
          products = Product.all()
          {products, context |> cache(:products, products)}
        end
      end

    This can be useful for situations where you have different lazy resolvers that
    depend on the same data, and you want to avoid fetching the data multiple times.

    With this approach, you can have the first resolver fetch the relevant data and
    cache it, then all other resolvers will use this cached data instead of refetching it.

    You can chain cache() calls as many times as you like if you need to store multiple values:

        context = context
          |> cache(:a, 1)
          |> cache(:b, 2)

    By default, the cache is scoped to the current identifier and current scope. What
    this means is that if you have a nested resolver for "products.photos" and you
    save something in the cache under key "a", it will be accessible from any other
    resolver for "products.photos" but not from a resolver for "products" or "products.title".

    You can change the scope of the cache by passing the `level` option to the cache()
    function:

        context
        |> cache(:a, 1, level: :parent)
        |> cache(:b, 2, level: :top)

    :parent in this case means it will be cached on the level of "products" for a resolver
    for "products.photos", and :top means it will be cached on the level of the root
    (accessible from any resolver in this scope). Your get_cache() calls will need to
    match the level of the cache() calls, so:

        # from products.photos
        context
        |> cache(:a, 1, level: :parent)

        # from products.photos
        get_cache(context, :a, level: :parent)

        # from products
        get_cache(context, :a) # implied level: :current


    Additionally, you can pass the `global` option to the cache() function to make the
    cache available from any scope. This is useful if you have a resolver that fetches
    data from the database and you want to cache it for the entire render.

    This means your cache call can "escape the scope" and define a cache for the entire
    render, even if you're inside another scope like a `{% for %}` call. Tread carefully
    with this option, as it can lead to unexpected results if you're not careful.

    `global: true` automtically implies `level: top`, so you don't need to pass both.
    Cache variables set with `global: true` will be accessible from anywhere:

        context
        |> cache(:a, 1, global: true)

        context
        |> get_cache(:a, 1) # works

        # elsewhere in another lazy resolver
        context
        |> get_cache(:a, 1) # works

    The above makes the :a key available for retrieval from any of your lazy resolvers
    across the entire render.

    Unlike with levels, you don't need to specify `global: true` on retrieval, as cache
    retrieval will automatically traverse up through parent scopes.
  """

  alias Liquex.{Scope, Context}

  @manual_cache_key :__manual_cache

  @spec cache_result(Liquex.Context.t(), any) :: Liquex.Context.t()
  @doc """
  Caches the result of the current lazy resolver in the context.

  Returns the updated context.
  """
  def cache_result(context, value) do
    if context.render_state[:in_child_resolver] do
      raise Liquex.Error,
            "cannot use result cache when in a dynamic resolver, use manual cache instead"
    end

    Liquex.Argument.assign(context, {:field, context.render_state.cache_key}, value)
  end

  @spec return_cached_result(Liquex.Context.t(), any) :: {any, Liquex.Context.t()}
  @doc """
  Helper function to return the result and the updated context with the cached result.

  Returns {value, updated_context}.
  """
  def return_cached_result(context, value) do
    if context.render_state[:in_child_resolver] do
      raise Liquex.Error,
            "cannot use result cache when in a dynamic resolver, use manual cache instead"
    end

    {value, cache_result(context, value)}
  end

  @spec cache(Liquex.Context.t(), any, any, keyword) :: Liquex.Context.t()
  @doc """
  Caches a value in the context under the given key.

  ## Options

  cache accepts the following options:

    * `:level` - the scope level to cache the value at. Can be one of `:current`, `:parent` or `:top`
    * `:global` - true/false to cache the value at the global scope (accessible from anywhere)

  Returns the updated context.
  """
  def cache(context, key, value, opts \\ []) do
    # or :parent or :top
    level = Keyword.get(opts, :level, :current)
    global = Keyword.get(opts, :global, false)

    level =
      if global do
        :top
      else
        level
      end

    new_key = build_manual_cache_key(level, key, context.render_state.cache_key)
    save_cache_item(context, new_key, value, @manual_cache_key, global: global)
  end

  @spec get_cached(Liquex.Context.t(), any, keyword) :: any
  @doc """
  Retrieves a cached a value in the context under the given key.

  ## Options

  cache accepts the following option:

    * `:level` - the scope level to retrieve the value from. Can be one of `:current`, `:parent` or `:top`

  Returns the cached value or nil if not found.
  """
  def get_cached(context, key, opts \\ []) do
    # or :parent or :top
    level = Keyword.get(opts, :level, :current)
    new_key = build_manual_cache_key(level, key, context.render_state.cache_key)

    get_from_cache(context, new_key, @manual_cache_key)
  end

  defp build_manual_cache_key(:current, key, cache_key), do: cache_key ++ [{:cache, key}]
  defp build_manual_cache_key(:top, key, _cache_key), do: [{:cache, key}]

  defp build_manual_cache_key(:parent, key, cache_key) do
    (cache_key |> Enum.reverse() |> tl() |> Enum.reverse()) ++ [{:cache, key}]
  end

  defp get_from_cache(%Context{scope: %Scope{stack: stack}}, key, cache_key) do
    stack
    |> Enum.reverse()
    |> Enum.reduce(nil, fn scope, acc ->
      fetched = Map.get(Map.get(scope, cache_key, %{}), key, nil)

      if fetched do
        fetched
      else
        acc
      end
    end)
  end

  defp save_cache_item(
         %Context{scope: %Scope{stack: stack} = scope} = context,
         key,
         value,
         cache_key,
         global: global
       ) do
    update_fn = fn scope ->
      current_result_cache = Map.get(scope, cache_key, %{})
      Map.put(scope, cache_key, Map.put(current_result_cache, key, value))
    end

    updated_scope =
      if global do
        {head, [last_scope | tail]} = Enum.split(stack, -1)
        updated_stack = head ++ [update_fn.(last_scope) | tail]
        Map.put(scope, :stack, updated_stack)
      else
        [current_scope | tail] = stack
        Map.put(scope, :stack, [update_fn.(current_scope) | tail])
      end

    Map.put(context, :scope, updated_scope)
  end
end
