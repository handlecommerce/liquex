defmodule Liquex.Math.Special do
  @moduledoc false

  # Sentinel for IEEE 754 specials that BEAM cannot represent natively
  # (Erlang's float type is restricted to finite values). Constructed by
  # arithmetic that overflows division by 0.0 and propagated through the
  # math filters and comparisons in expressions, matching Liquid's rendering
  # of `Float::INFINITY` / `Float::NAN`.

  defstruct [:type]
  @type t :: %__MODULE__{type: :infinity | :neg_infinity | :nan}

  defimpl String.Chars do
    def to_string(%{type: :infinity}), do: "Infinity"
    def to_string(%{type: :neg_infinity}), do: "-Infinity"
    def to_string(%{type: :nan}), do: "NaN"
  end

  defimpl Inspect do
    def inspect(%{type: :infinity}, _), do: "#Liquex.Math<Infinity>"
    def inspect(%{type: :neg_infinity}, _), do: "#Liquex.Math<-Infinity>"
    def inspect(%{type: :nan}, _), do: "#Liquex.Math<NaN>"
  end
end

defmodule Liquex.Math do
  @moduledoc false

  alias Liquex.Math.Special

  @infinity %Special{type: :infinity}
  @neg_infinity %Special{type: :neg_infinity}
  @nan %Special{type: :nan}

  def infinity, do: @infinity
  def neg_infinity, do: @neg_infinity
  def nan, do: @nan

  def special?(%Special{}), do: true
  def special?(_), do: false

  def nan?(%Special{type: :nan}), do: true
  def nan?(_), do: false

  def infinite?(%Special{type: t}) when t in [:infinity, :neg_infinity], do: true
  def infinite?(_), do: false

  # Build the appropriate special when dividing by zero. Mirrors IEEE 754:
  #  +x / +0.0 -> +inf,  -x / +0.0 -> -inf,  0 / +0.0 -> NaN.
  def from_zero_div(value) when is_number(value) do
    cond do
      value > 0 -> @infinity
      value < 0 -> @neg_infinity
      true -> @nan
    end
  end

  def from_zero_div(@infinity), do: @infinity
  def from_zero_div(@neg_infinity), do: @neg_infinity
  def from_zero_div(@nan), do: @nan

  # ---- Arithmetic ---------------------------------------------------------

  def add(@nan, _), do: @nan
  def add(_, @nan), do: @nan
  def add(@infinity, @neg_infinity), do: @nan
  def add(@neg_infinity, @infinity), do: @nan
  def add(@infinity, _), do: @infinity
  def add(_, @infinity), do: @infinity
  def add(@neg_infinity, _), do: @neg_infinity
  def add(_, @neg_infinity), do: @neg_infinity
  def add(a, b) when is_number(a) and is_number(b), do: a + b

  def sub(a, b), do: add(a, negate(b))

  def mul(@nan, _), do: @nan
  def mul(_, @nan), do: @nan

  def mul(%Special{type: t}, b) when t in [:infinity, :neg_infinity] and is_number(b),
    do: mul_inf(t, b)

  def mul(a, %Special{type: t}) when t in [:infinity, :neg_infinity] and is_number(a),
    do: mul_inf(t, a)

  def mul(@infinity, @infinity), do: @infinity
  def mul(@neg_infinity, @neg_infinity), do: @infinity
  def mul(@infinity, @neg_infinity), do: @neg_infinity
  def mul(@neg_infinity, @infinity), do: @neg_infinity
  def mul(a, b) when is_number(a) and is_number(b), do: a * b

  defp mul_inf(_, +0.0), do: @nan
  defp mul_inf(_, 0), do: @nan
  defp mul_inf(:infinity, n) when n > 0, do: @infinity
  defp mul_inf(:infinity, _), do: @neg_infinity
  defp mul_inf(:neg_infinity, n) when n > 0, do: @neg_infinity
  defp mul_inf(:neg_infinity, _), do: @infinity

  def divide(@nan, _), do: @nan
  def divide(_, @nan), do: @nan
  def divide(%Special{}, %Special{}), do: @nan

  def divide(%Special{type: t}, b) when is_number(b) do
    cond do
      t == :infinity and b > 0 -> @infinity
      t == :infinity and b < 0 -> @neg_infinity
      t == :neg_infinity and b > 0 -> @neg_infinity
      t == :neg_infinity and b < 0 -> @infinity
      b == 0 and t == :infinity -> @infinity
      b == 0 -> @neg_infinity
    end
  end

  def divide(a, %Special{type: t}) when is_number(a) and t in [:infinity, :neg_infinity], do: 0.0

  def divide(a, b) when is_number(a) and is_number(b) do
    cond do
      b == 0 and is_float(b) -> from_zero_div(a)
      b == 0 -> {:zero_division}
      true -> a / b
    end
  end

  def modulo(@nan, _), do: @nan
  def modulo(_, @nan), do: @nan
  def modulo(%Special{type: t}, _) when t in [:infinity, :neg_infinity], do: @nan

  def modulo(a, %Special{type: t}) when is_number(a) and t in [:infinity, :neg_infinity],
    do: a * 1.0

  def modulo(a, b) when is_number(a) and is_number(b) do
    cond do
      b == 0 and is_float(b) -> @nan
      b == 0 -> {:zero_division}
      is_float(a) or is_float(b) -> :math.fmod(a, b)
      true -> rem(a, b)
    end
  end

  def negate(@infinity), do: @neg_infinity
  def negate(@neg_infinity), do: @infinity
  def negate(@nan), do: @nan
  def negate(n) when is_number(n), do: -n

  def absolute(@infinity), do: @infinity
  def absolute(@neg_infinity), do: @infinity
  def absolute(@nan), do: @nan
  def absolute(n) when is_number(n), do: abs(n)

  # ---- Comparison ---------------------------------------------------------

  # :nan means "comparison is unordered"; equality/ordering ops should all
  # evaluate false except `!=` which is true.
  def compare(@nan, _), do: :nan
  def compare(_, @nan), do: :nan
  def compare(@infinity, @infinity), do: :eq
  def compare(@neg_infinity, @neg_infinity), do: :eq
  def compare(@infinity, _), do: :gt
  def compare(_, @infinity), do: :lt
  def compare(@neg_infinity, _), do: :lt
  def compare(_, @neg_infinity), do: :gt

  def compare(a, b) when is_number(a) and is_number(b) do
    cond do
      a < b -> :lt
      a > b -> :gt
      true -> :eq
    end
  end

  # Apply a Liquid comparison op (:==, :!=, :<, :>, :<=, :>=) to two operands
  # when at least one is special.
  def apply_op(op, a, b) do
    case compare(a, b) do
      :nan -> op == :!=
      :eq -> op in [:==, :<=, :>=]
      :lt -> op in [:!=, :<, :<=]
      :gt -> op in [:!=, :>, :>=]
    end
  end

  # Liquid's "Computation results in 'X'" error message format used by
  # floor/ceil/round when given a non-finite input.
  def computation_error(%Special{type: :nan}),
    do: "Liquid error: Computation results in 'NaN' (Not a Number)"

  def computation_error(%Special{} = s),
    do: "Liquid error: Computation results in '#{s}'"
end
