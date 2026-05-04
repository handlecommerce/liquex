defmodule Liquex.Indifferent do
  @moduledoc false

  alias Liquex.Drop

  @spec get(map, any, any) :: any
  @doc """
  Gets a value from a map using indifferent access

    ## Examples

      iex> Liquex.Indifferent.get(%{"a" => "Hello"}, "a")
      "Hello"

      iex> Liquex.Indifferent.get(%{a: "Hello"}, "a")
      "Hello"

      iex> Liquex.Indifferent.get(%{a: "Hello"}, :a)
      "Hello"

      iex> Liquex.Indifferent.get(%{a: "Hello"}, "b")
      nil

      iex> Liquex.Indifferent.get(%{a: "Hello"}, "b", "Goodbye")
      "Goodbye"

      iex> Liquex.Indifferent.get(%TestAccessModule{}, :atom_test)
      %{title: "Atom Test"}

      iex> Liquex.Indifferent.get(%TestAccessModule{}, "atom_test")
      %{title: "Atom Test"}

      iex> Liquex.Indifferent.get(%TestNonAccessModule{x: "Hello World!"}, :x)
      "Hello World!"

      iex> Liquex.Indifferent.get(%TestNonAccessModule{x: "Hello World!"}, "x")
      "Hello World!"
  """
  def get(map, key, default \\ nil) do
    case fetch(map, key) do
      {:ok, value} -> value
      :error -> default
    end
  end

  @spec put(map, any, any) :: map
  @doc """
  Puts a value in a key using indifferent access

    ## Examples

      iex> Liquex.Indifferent.put(%{"a" => "Hello"}, "a", "World")
      %{"a" => "World"}

      iex> Liquex.Indifferent.put(%{"a" => "Hello"}, :a, "World")
      %{"a" => "World"}

      iex> Liquex.Indifferent.put(%{a: "Hello"}, "b", "World")
      %{"b" => "World", :a => "Hello"}
  """
  def put(map, key, value) when is_struct(map) do
    if implements_behaviour?(map, Access) do
      Access.get_and_update(map, key, &{&1, value}) |> elem(1)
    else
      put(Map.from_struct(map), key, value)
    end
  end

  def put(map, key, value), do: Map.put(map, get_key!(map, key, key), value)

  @spec fetch(map, any) :: {:ok, term} | :error
  @doc """
  Fetches a value from a map using indifferent access

    ## Examples

      iex> Liquex.Indifferent.fetch(%{"a" => "Hello"}, "a")
      {:ok, "Hello"}

      iex> Liquex.Indifferent.fetch(%{a: "Hello"}, "a")
      {:ok, "Hello"}

      iex> Liquex.Indifferent.fetch(%{a: "Hello"}, :a)
      {:ok, "Hello"}

      iex> Liquex.Indifferent.fetch(%{a: "Hello"}, "b")
      :error

      iex> Liquex.Indifferent.fetch(%{:a => "Hello", "a" => "Goodbye"}, "a")
      {:ok, "Goodbye"}

      iex> Liquex.Indifferent.fetch(%TestAccessModule{}, :atom_test)
      {:ok, %{title: "Atom Test"}}

      iex> Liquex.Indifferent.fetch(%TestAccessModule{}, "atom_test")
      {:ok, %{title: "Atom Test"}}
  """
  def fetch(data, key) do
    case access(data, key) do
      {:ok, _} = result ->
        result

      :error ->
        # try either a string or atom

        cond do
          is_binary(key) -> access(data, String.to_existing_atom(key))
          is_atom(key) -> access(data, Atom.to_string(key))
          true -> :error
        end
    end
  rescue
    ArgumentError -> :error
  end

  @spec fetch(map | struct, any, Liquex.Context.t()) :: {{:ok, term} | :error, Liquex.Context.t()}
  @doc """
  Like `fetch/2`, but routes through `Liquex.Drop.fetch/3` for structs that
  declare the behaviour, threading the render context.

  Returns `{result, context}`. The context is unchanged for non-Drop data; for
  Drops it may carry a memoized entry under `private[:drop_cache]` (set up
  in Phase 3 of the per-render Drop cache).
  """
  def fetch(data, key, context) do
    case attempt(data, key, context) do
      {{:ok, _value}, _context} = result ->
        result

      {:error, context} ->
        cond do
          is_binary(key) ->
            try_alternate(data, String.to_existing_atom(key), context)

          is_atom(key) ->
            attempt(data, Atom.to_string(key), context)

          true ->
            {:error, context}
        end
    end
  rescue
    ArgumentError -> {:error, context}
  end

  defp try_alternate(data, key, context), do: attempt(data, key, context)

  defp attempt(data, key, context) when is_struct(data) do
    cond do
      Drop.drop?(data) ->
        cached_drop_fetch(data, key, context)

      implements_behaviour?(data, Access) ->
        {Access.fetch(data, key), context}

      true ->
        {Map.fetch(data, key), context}
    end
  end

  defp attempt(data, key, context), do: {Access.fetch(data, key), context}

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

  defp cache_get(%Liquex.Context{private: %{drop_cache: cache}}, drop, key) do
    case Map.fetch(cache, {drop, key}) do
      {:ok, value} -> {:ok, value}
      :error -> :miss
    end
  end

  defp cache_get(_context, _drop, _key), do: :miss

  defp cache_put(%Liquex.Context{private: private} = context, drop, key, value) do
    cache = Map.get(private, :drop_cache, %{})
    %{context | private: Map.put(private, :drop_cache, Map.put(cache, {drop, key}, value))}
  end

  @spec get(map | struct, any, any, Liquex.Context.t()) :: {any, Liquex.Context.t()}
  @doc """
  Context-threading variant of `get/3`. Returns `{value, context}`.
  """
  def get(data, key, default, context) do
    case fetch(data, key, context) do
      {{:ok, value}, context} -> {value, context}
      {:error, context} -> {default, context}
    end
  end

  def get_and_update(data, key, fun) when is_function(fun) do
    current_value =
      case fetch(data, key) do
        {:ok, value} -> value
        :error -> nil
      end

    case fun.(current_value) do
      {current_value, new_value} -> {current_value, put(data, key, new_value)}
      :pop -> {current_value, put(data, key, nil)}
    end
  end

  def update(data, key, default, fun) when is_function(fun) do
    case access(data, key) do
      {:ok, value} -> put(data, key, fun.(value))
      :error -> put(data, key, default)
    end
  end

  def has_key?(data, key) do
    case fetch(data, key) do
      {:ok, _} -> true
      _ -> false
    end
  end

  defp get_key(map, key) do
    cond do
      implements_behaviour?(map, Access) ->
        {:ok, key}

      Map.has_key?(map, key) ->
        {:ok, key}

      is_binary(key) ->
        key = String.to_existing_atom(key)
        if Map.has_key?(map, key), do: {:ok, key}, else: :error

      is_atom(key) ->
        key = Atom.to_string(key)
        if Map.has_key?(map, key), do: {:ok, key}, else: :error

      true ->
        :error
    end
  rescue
    ArgumentError -> :error
  end

  defp get_key!(map, key, default) do
    case get_key(map, key) do
      {:ok, key} -> key
      _ -> default
    end
  end

  # Access a map/struct by key using either Map.fetch/2 or Access.fetch/2
  defp access(data, key) when is_struct(data) do
    # Structs don't allow Access.fetch/2 access without implementing Access so
    # fallback to Map.fetch/2
    if implements_behaviour?(data, Access) do
      Access.fetch(data, key)
    else
      Map.fetch(data, key)
    end
  end

  defp access(data, key), do: Access.fetch(data, key)

  defp implements_behaviour?(map, behaviour) when is_struct(map) do
    map.__struct__.module_info()[:attributes]
    |> Keyword.get(:behaviour, [])
    |> Enum.member?(behaviour)
  end

  defp implements_behaviour?(_, _), do: false
end
