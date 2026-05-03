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

  # Liquid converts native floats to BigDecimal via the float's string form so
  # that arithmetic preserves the human-readable value (`9.99` stays `9.99`,
  # not the IEEE-noise `9.99000000000000017...`). We mirror that with `Decimal`:
  # `9.99 + 14.5` becomes `Decimal.add(Decimal.new("9.99"), Decimal.new("14.5"))
  # == Decimal "24.49"`. The result is rendered by converting Decimal to Float
  # for shortest-round-trip output (matching Ruby's `BigDecimal#to_f` then
  # `Float#to_s`).
  defp to_decimal(%Decimal{} = d), do: d
  defp to_decimal(n) when is_integer(n), do: Decimal.new(n)
  defp to_decimal(n) when is_float(n), do: n |> Float.to_string() |> Decimal.new()

  defp dec_zero?(%Decimal{} = d), do: Decimal.equal?(d, 0)
  defp dec_zero?(n) when is_integer(n) or is_float(n), do: n == 0

  defp dec_positive?(%Decimal{} = d), do: Decimal.positive?(d)
  defp dec_positive?(n) when is_number(n), do: n > 0

  defp dec_negative?(%Decimal{} = d), do: Decimal.negative?(d)
  defp dec_negative?(n) when is_number(n), do: n < 0

  # Build the appropriate special when dividing by zero. Mirrors IEEE 754:
  #  +x / +0.0 -> +inf,  -x / +0.0 -> -inf,  0 / +0.0 -> NaN.
  def from_zero_div(value) do
    cond do
      special?(value) -> value
      dec_positive?(value) -> @infinity
      dec_negative?(value) -> @neg_infinity
      true -> @nan
    end
  end

  # ---- Arithmetic ---------------------------------------------------------

  def add(@nan, _), do: @nan
  def add(_, @nan), do: @nan
  def add(@infinity, @neg_infinity), do: @nan
  def add(@neg_infinity, @infinity), do: @nan
  def add(@infinity, _), do: @infinity
  def add(_, @infinity), do: @infinity
  def add(@neg_infinity, _), do: @neg_infinity
  def add(_, @neg_infinity), do: @neg_infinity
  def add(a, b) when is_integer(a) and is_integer(b), do: a + b
  def add(a, b), do: Decimal.add(to_decimal(a), to_decimal(b))

  def sub(a, b), do: add(a, negate(b))

  def mul(@nan, _), do: @nan
  def mul(_, @nan), do: @nan

  def mul(%Special{type: t}, b) when t in [:infinity, :neg_infinity],
    do: mul_inf(t, b)

  def mul(a, %Special{type: t}) when t in [:infinity, :neg_infinity],
    do: mul_inf(t, a)

  def mul(a, b) when is_integer(a) and is_integer(b), do: a * b
  def mul(a, b), do: Decimal.mult(to_decimal(a), to_decimal(b))

  defp mul_inf(:infinity, %Special{type: :infinity}), do: @infinity
  defp mul_inf(:infinity, %Special{type: :neg_infinity}), do: @neg_infinity
  defp mul_inf(:neg_infinity, %Special{type: :infinity}), do: @neg_infinity
  defp mul_inf(:neg_infinity, %Special{type: :neg_infinity}), do: @infinity

  defp mul_inf(t, x) do
    cond do
      dec_zero?(x) -> @nan
      dec_positive?(x) -> if t == :infinity, do: @infinity, else: @neg_infinity
      true -> if t == :infinity, do: @neg_infinity, else: @infinity
    end
  end

  def divide(@nan, _), do: @nan
  def divide(_, @nan), do: @nan
  def divide(%Special{}, %Special{}), do: @nan

  def divide(%Special{type: t}, b) do
    cond do
      special?(b) -> @nan
      t == :infinity and dec_positive?(b) -> @infinity
      t == :infinity and dec_negative?(b) -> @neg_infinity
      t == :neg_infinity and dec_positive?(b) -> @neg_infinity
      t == :neg_infinity and dec_negative?(b) -> @infinity
      # Division of infinity by zero preserves the infinity's sign.
      t == :infinity -> @infinity
      true -> @neg_infinity
    end
  end

  def divide(_a, %Special{type: t}) when t in [:infinity, :neg_infinity], do: 0.0

  def divide(a, b) when is_integer(a) and is_integer(b) do
    cond do
      b == 0 -> {:zero_division}
      true -> Integer.floor_div(a, b)
    end
  end

  def divide(a, b) do
    cond do
      dec_zero?(b) and (is_float(b) or match?(%Decimal{}, b)) ->
        from_zero_div(a)

      dec_zero?(b) ->
        {:zero_division}

      true ->
        Decimal.div(to_decimal(a), to_decimal(b))
    end
  end

  def modulo(@nan, _), do: @nan
  def modulo(_, @nan), do: @nan
  def modulo(%Special{type: t}, _) when t in [:infinity, :neg_infinity], do: @nan

  def modulo(a, %Special{type: t}) when t in [:infinity, :neg_infinity] do
    # Liquid renders a finite modulo by infinity as the value coerced to a
    # Float (`10` -> `10.0`).
    case a do
      n when is_integer(n) -> n * 1.0
      n when is_float(n) -> n
      %Decimal{} = d -> Decimal.to_float(d)
    end
  end

  def modulo(a, b) when is_integer(a) and is_integer(b) do
    cond do
      b == 0 -> {:zero_division}
      true -> Integer.mod(a, b)
    end
  end

  def modulo(a, b) do
    cond do
      dec_zero?(b) and (is_float(b) or match?(%Decimal{}, b)) -> @nan
      dec_zero?(b) -> {:zero_division}
      true -> dec_mod(to_decimal(a), to_decimal(b))
    end
  end

  # Ruby-style remainder: a - b * floor(a / b). Sign matches the divisor.
  defp dec_mod(a, b) do
    quotient = a |> Decimal.div(b) |> Decimal.round(0, :floor)
    Decimal.sub(a, Decimal.mult(b, quotient))
  end

  def negate(@infinity), do: @neg_infinity
  def negate(@neg_infinity), do: @infinity
  def negate(@nan), do: @nan
  def negate(n) when is_number(n), do: -n
  def negate(%Decimal{} = d), do: Decimal.negate(d)

  def absolute(@infinity), do: @infinity
  def absolute(@neg_infinity), do: @infinity
  def absolute(@nan), do: @nan
  def absolute(n) when is_number(n), do: abs(n)
  def absolute(%Decimal{} = d), do: Decimal.abs(d)

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

  def compare(a, b), do: Decimal.compare(to_decimal(a), to_decimal(b))

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
