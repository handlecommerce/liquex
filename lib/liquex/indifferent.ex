defmodule Liquex.Indifferent do
  @moduledoc false

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

      iex> Liquex.Indifferent.get(%StructWithAccess{key: "Hello"}, :key)
      "Hello World"
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

      iex> Liquex.Indifferent.put(%{a: "Hello"}, "b", "World")
      %{"b" => "World", :a => "Hello"}
  """
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

      iex> Liquex.Indifferent.fetch(%StructWithAccess{key: "Hello"}, :key)
      {:ok, "Hello World"}
  """
  def fetch(data, key) when is_struct(data) do
    if implements_access_fetch_behaviour?(data) do
      Access.fetch(data, key)
    else
      Map.fetch(data, get_key!(data, key, key))
    end
  end

  def fetch(data, key), do: Map.fetch(data, get_key!(data, key, key))

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

  defp implements_access_fetch_behaviour?(struct) do
    Kernel.function_exported?(struct.__struct__, :fetch, 2)
  end
end
