defprotocol Liquex.Collection do
  @spec limit(t, pos_integer()) :: t
  def limit(collection, limit)

  @spec offset(t, pos_integer()) :: t
  def offset(collection, offset)

  @spec reverse(t) :: t
  def reverse(collection)

  @spec to_enumerable(t) :: Enumerable.t()
  def to_enumerable(collection)
end

defimpl Liquex.Collection, for: [Enumerable, List] do
  def limit(collection, limit), do: Enum.take(collection, limit)
  def offset(collection, offset), do: Enum.drop(collection, offset)
  def reverse(collection), do: Enum.reverse(collection)
  def to_enumerable(collection), do: collection
end
