defprotocol Liquex.Collection do
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
  @spec limit(any, integer) :: [any]
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
