defmodule Liquex.Resolver do
  @moduledoc false
  # Template variable resolution.
  #
  # `.` traversal in templates lands here. The dispatch order is:
  #
  #   1. `Liquex.Context` — resolves `{{ products }}` against the scope
  #      stack, environment, and static environment.
  #   2. `Range` — `.size`/`.first`/`.last` via `Liquex.Drop.Range`,
  #      mirroring how Ruby Liquid array-coerces ranges so those
  #      attributes work.
  #   3. User-defined `Liquex.Drop` structs — dispatched through their
  #      `fetch/3` callback, with results memoized in
  #      `context.private[:drop_cache]` (gated by `cacheable?/1`).
  #   4. Plain structs / maps — `Map.fetch/2`.
  #
  # The render context is threaded so Drops can both read it and write
  # cache entries back to it. `Liquex.Indifferent` handles the leaf
  # atom/string-key fallback and stays unaware of any of this.

  alias Liquex.Context
  alias Liquex.Drop

  @spec fetch(map | struct, any, Context.t()) :: {{:ok, term} | :error, Context.t()}
  def fetch(data, key, context) do
    case attempt(data, key, context) do
      {{:ok, _value}, _context} = result ->
        result

      {:error, context} ->
        cond do
          is_binary(key) ->
            attempt(data, String.to_existing_atom(key), context)

          is_atom(key) ->
            attempt(data, Atom.to_string(key), context)

          true ->
            {:error, context}
        end
    end
  rescue
    ArgumentError -> {:error, context}
  end

  @spec get(map | struct, any, any, Context.t()) :: {any, Context.t()}
  def get(data, key, default, context) do
    case fetch(data, key, context) do
      {{:ok, value}, context} -> {value, context}
      {:error, context} -> {default, context}
    end
  end

  defp attempt(%Context{} = ctx, key, context),
    do: {Context.fetch(ctx, key), context}

  defp attempt(%Range{} = r, key, context),
    do: {Liquex.Drop.Range.fetch(r, key, context), context}

  defp attempt(data, key, context) when is_struct(data) do
    if Drop.drop?(data) do
      cached_drop_fetch(data, key, context)
    else
      {Map.fetch(data, key), context}
    end
  end

  defp attempt(data, key, context), do: {Map.fetch(data, key), context}

  defp cached_drop_fetch(drop, key, context) do
    if Drop.cacheable?(drop) do
      case cache_get(context, drop, key) do
        {:ok, cached} ->
          {cached, context}

        :miss ->
          result = drop.__struct__.fetch(drop, key, context)
          {result, cache_put(context, drop, key, result)}
      end
    else
      {drop.__struct__.fetch(drop, key, context), context}
    end
  end

  defp cache_get(%Context{private: %{drop_cache: cache}}, drop, key) do
    case Map.fetch(cache, {drop, key}) do
      {:ok, value} -> {:ok, value}
      :error -> :miss
    end
  end

  defp cache_get(_context, _drop, _key), do: :miss

  defp cache_put(%Context{private: private} = context, drop, key, value) do
    cache = Map.get(private, :drop_cache, %{})
    %{context | private: Map.put(private, :drop_cache, Map.put(cache, {drop, key}, value))}
  end
end
