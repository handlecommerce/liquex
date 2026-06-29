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
  matched against Shopify Liquid 5.12+ semantics: `empty` matches `""`, `[]`,
  and `{}`; `blank` matches values that are blank under Shopify Liquid (`""`,
  whitespace-only strings, `[]`, `{}`, `nil`, and `false`).
  """
  def equal?(%__MODULE__{type: :empty}, other), do: empty_value?(other)
  def equal?(other, %__MODULE__{type: :empty}), do: empty_value?(other)
  def equal?(%__MODULE__{type: :blank}, other), do: blank_value?(other)
  def equal?(other, %__MODULE__{type: :blank}), do: blank_value?(other)

  defp empty_value?(""), do: true
  defp empty_value?([]), do: true
  defp empty_value?(map) when is_map(map) and not is_struct(map), do: map_size(map) == 0
  defp empty_value?(_), do: false

  defp blank_value?(nil), do: true
  defp blank_value?(false), do: true
  defp blank_value?(""), do: true
  defp blank_value?(str) when is_binary(str), do: String.trim(str) == ""
  defp blank_value?([]), do: true
  defp blank_value?(map) when is_map(map) and not is_struct(map), do: map_size(map) == 0
  defp blank_value?(_), do: false

  defimpl String.Chars do
    def to_string(_), do: ""
  end
end
