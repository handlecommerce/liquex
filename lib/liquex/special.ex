defmodule Liquex.Special do
  @moduledoc false

  # Sentinel for the `empty` / `blank` keywords. Liquid resolves these to a
  # MethodLiteral that triggers `empty?` / `blank?` dispatch in `==`/`!=`
  # comparisons and renders as an empty string everywhere else.

  defstruct [:type]

  @type t :: %__MODULE__{type: :empty | :blank}

  def empty, do: %__MODULE__{type: :empty}
  def blank, do: %__MODULE__{type: :blank}

  @doc """
  Equality dispatch for the `empty` / `blank` keywords. The other operand is
  matched against Ruby's `empty?` / `blank?` semantics in plain Liquid (no
  Rails extensions): `empty` matches `""`, `[]`, and `{}`; `blank` matches
  nothing because plain Ruby objects do not respond to `blank?`.
  """
  def equal?(%__MODULE__{type: :empty}, other), do: empty_value?(other)
  def equal?(other, %__MODULE__{type: :empty}), do: empty_value?(other)
  def equal?(%__MODULE__{type: :blank}, _), do: false
  def equal?(_, %__MODULE__{type: :blank}), do: false

  defp empty_value?(""), do: true
  defp empty_value?([]), do: true
  defp empty_value?(map) when is_map(map) and not is_struct(map), do: map_size(map) == 0
  defp empty_value?(_), do: false

  defimpl String.Chars do
    def to_string(_), do: ""
  end
end
