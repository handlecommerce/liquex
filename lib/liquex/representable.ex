defprotocol Liquex.Representable do
  @fallback_to_any true

  @spec represent(term, boolean) :: term
  def represent(representable, lazy \\ false)

  @spec is_lazy(term) :: boolean
  def is_lazy(representable)
end

defimpl Liquex.Representable, for: [Date, Time, DateTime, NaiveDateTime] do
  def represent(representable, _), do: representable
  def is_lazy(_), do: false
end

defimpl Liquex.Representable, for: Any do
  alias Liquex.Represent

  def represent(representable, lazy), do: Represent.represent(representable, lazy)
  def is_lazy(representable) when is_list(representable), do: true
  def is_lazy(representable) when is_map(representable), do: true

  def is_lazy(_), do: false
end
