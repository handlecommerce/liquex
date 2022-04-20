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
    map.__struct__.module_info[:attributes]
    |> Keyword.get(:behaviour, [])
    |> Enum.member?(behaviour)
  end

  defp implements_behaviour?(_, _), do: false
end
