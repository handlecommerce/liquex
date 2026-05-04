defmodule Liquex.Indifferent do
  @moduledoc false

  # Atom/string-key indifferent access for plain maps and structs.
  # Mirrors Rails' `HashWithIndifferentAccess`: a lookup with key `"foo"`
  # finds a value at `%{"foo" => v}` or `%{foo: v}`, and the same goes
  # for `:foo`. Used as the leaf-level utility under
  # `Liquex.Resolver`, which handles the higher-level dispatch through
  # Drops, the render context, and stdlib adapters.

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
  def put(map, key, value) when is_struct(map),
    do: put(Map.from_struct(map), key, value)

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
  """
  def fetch(data, key) do
    case access(data, key) do
      {:ok, _} = result ->
        result

      :error ->
        cond do
          is_binary(key) -> access(data, String.to_existing_atom(key))
          is_atom(key) -> access(data, Atom.to_string(key))
          true -> :error
        end
    end
  rescue
    ArgumentError -> :error
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

  defp access(data, key) when is_struct(data), do: Map.fetch(data, key)
  defp access(data, key), do: Map.fetch(data, key)
end
