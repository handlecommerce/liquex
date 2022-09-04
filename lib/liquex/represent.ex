defmodule Liquex.Represent do
  @moduledoc """
  Helper methods for maps
  """

  alias Liquex.Representable

  @doc """
  Convert any object and deeply maps atom keys to strings

  The value `deep` determines if it should eagerly represent the object. If
  set to false, it will return a function for any nested objects.

  Lazy values are automatically evaluated in the Liquid rendering engine.
  """
  @spec represent(any, boolean) :: any
  def represent(value, lazy \\ false)

  def represent(struct, lazy) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> represent(lazy)
  end

  def represent(value, lazy) when is_map(value) do
    value
    |> Enum.map(&to_string_key(&1, lazy))
    |> Enum.into(%{})
  end

  # Walk the list and represent the keys of of any map members
  def represent(value, lazy) when is_list(value), do: Enum.map(value, &lazy_represent(&1, lazy))

  def represent(value, _), do: value

  @spec expand(term) :: term
  @doc """
  Expands a previously represented object.

  Useful when the represented object contains lazy fields. This can be useful
  for generating JSON values from a represented object. For example, if you
  had a `dump` filter that dumped a value to the page as JSON, you would use
  this function so that lazy functions get represented correctly instead of
  as functions.
  """
  def expand(value) when is_struct(value), do: value
  def expand(value) when is_function(value), do: expand(value.())

  def expand(value) when is_map(value) do
    value
    |> Enum.map(fn {k, v} -> {k, expand(v)} end)
    |> Enum.into(%{})
  end

  def expand(value) when is_list(value), do: Enum.map(value, &expand/1)
  def expand(value), do: value

  defp to_string_key({k, v}, lazy) when is_atom(k),
    do: to_string_key({Atom.to_string(k), v}, lazy)

  defp to_string_key({k, v}, lazy), do: {k, lazy_represent(v, lazy)}

  defp lazy_represent(value, true) do
    case Representable.is_lazy(value) do
      true -> fn -> Liquex.Representable.represent(value, true) end
      _ -> Liquex.Representable.represent(value, true)
    end
  end

  defp lazy_represent(v, false), do: Liquex.Representable.represent(v, false)
end
