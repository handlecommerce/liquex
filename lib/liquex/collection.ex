defprotocol Liquex.Collection do
  @type t :: term

  @spec limit(t, pos_integer()) :: t
  def limit(collection, limit)

  @spec offset(t, pos_integer()) :: t
  def offset(collection, offset)

  @spec reverse(t) :: t
  def reverse(collection)

  @spec sort(t) :: t
  def sort(collection)

  @spec sort(t, String.t()) :: t
  def sort(collection, field_name)

  @spec sort_case_insensitive(t) :: t
  def sort_case_insensitive(collection)

  @spec sort_case_insensitive(t, String.t()) :: t
  def sort_case_insensitive(collection, field_name)

  @spec where(t, String.t()) :: t
  def where(collection, field_name)

  @spec where(t, String.t(), term) :: t
  def where(collection, field_name, value)

  @spec to_enumerable(t) :: Enumerable.t()
  def to_enumerable(collection)
end

defimpl Liquex.Collection, for: [Enumerable, List, Range] do
  def limit(collection, limit), do: Enum.take(collection, limit)

  def offset(collection, offset), do: Enum.drop(collection, offset)

  def reverse(collection), do: Enum.reverse(collection)

  def sort(collection), do: Enum.sort(collection)

  def sort(collection, field_name),
    do: Enum.sort_by(collection, &Liquex.Indifferent.get(&1, field_name))

  def sort_case_insensitive(collection) do
    Enum.sort_by(collection, fn
      value when is_binary(value) -> String.downcase(value)
      value -> value
    end)
  end

  def sort_case_insensitive(collection, field_name) do
    Enum.sort_by(collection, fn record ->
      case Liquex.Indifferent.get(record, field_name) do
        value when is_binary(value) -> String.downcase(value)
        value -> value
      end
    end)
  end

  def where(collection, field_name) do
    collection
    |> Enum.filter(fn v ->
      case Liquex.Indifferent.get(v, field_name) do
        false -> false
        nil -> false
        _ -> true
      end
    end)
  end

  def where(collection, field_name, value) do
    collection
    |> Enum.filter(&(Liquex.Indifferent.get(&1, field_name) == value))
  end

  def to_enumerable(collection), do: collection
end

# Liquid iterates hashes by yielding [key, value] pairs. Match that so
# `{% for pair in h %}` exposes `pair[0]` / `pair[1]` / `pair.first` / `pair.last`.
defimpl Liquex.Collection, for: Map do
  defp to_pairs(map) when is_struct(map),
    do: map |> Map.from_struct() |> to_pairs()

  defp to_pairs(map), do: Enum.map(map, fn {k, v} -> [k, v] end)

  def limit(map, limit), do: map |> to_pairs() |> Enum.take(limit)
  def offset(map, offset), do: map |> to_pairs() |> Enum.drop(offset)
  def reverse(map), do: map |> to_pairs() |> Enum.reverse()
  def sort(map), do: map |> to_pairs() |> Enum.sort()

  def sort(map, field_name),
    do:
      map
      |> to_pairs()
      |> Enum.sort_by(&Liquex.Indifferent.get(&1, field_name))

  def sort_case_insensitive(map),
    do:
      map
      |> to_pairs()
      |> Enum.sort_by(fn
        v when is_binary(v) -> String.downcase(v)
        v -> v
      end)

  def sort_case_insensitive(map, field_name),
    do:
      map
      |> to_pairs()
      |> Enum.sort_by(fn record ->
        case Liquex.Indifferent.get(record, field_name) do
          v when is_binary(v) -> String.downcase(v)
          v -> v
        end
      end)

  def where(map, field_name),
    do:
      map
      |> to_pairs()
      |> Enum.filter(fn v ->
        case Liquex.Indifferent.get(v, field_name) do
          false -> false
          nil -> false
          _ -> true
        end
      end)

  def where(map, field_name, value),
    do:
      map
      |> to_pairs()
      |> Enum.filter(&(Liquex.Indifferent.get(&1, field_name) == value))

  def to_enumerable(map), do: to_pairs(map)
end
