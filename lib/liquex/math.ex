defmodule Liquex.Math do
  @moduledoc false

  # Numeric helpers that mirror Liquid's BigDecimal-backed arithmetic.
  #
  # - Integer arithmetic stays Integer (5 + 3 = 8).
  # - Anything involving a Float, Decimal, or special value goes through
  #   `Decimal` so `9.99 + 14.5` is exactly `Decimal "24.49"` instead of the
  #   IEEE-noise `24.490000000000002`.
  # - IEEE 754 specials (Infinity, -Infinity, NaN) are Decimal's native
  #   representations: `Decimal.new("Infinity")` etc. Their `String.Chars`
  #   form is already `"Infinity"` / `"-Infinity"` / `"NaN"`, matching
  #   Liquid's `Float::INFINITY.to_s` and friends.
  # - We run all Decimal calls inside a context with traps disabled so
  #   invalid operations (`Inf - Inf`, `Inf * 0`) return signaling values
  #   instead of raising.

  @ctx %Decimal.Context{
    precision: 28,
    rounding: :half_up,
    flags: [],
    traps: []
  }

  defp with_ctx(fun), do: Decimal.Context.with(@ctx, fun)

  # ---- Constructors and predicates ---------------------------------------

  def infinity, do: Decimal.new("Infinity")
  def neg_infinity, do: Decimal.new("-Infinity")
  def nan, do: Decimal.new("NaN")

  def special?(%Decimal{coef: c}) when c in [:inf, :NaN, :qNaN, :sNaN], do: true
  def special?(_), do: false

  def nan?(%Decimal{coef: c}) when c in [:NaN, :qNaN, :sNaN], do: true
  def nan?(_), do: false

  def infinite?(%Decimal{coef: :inf}), do: true
  def infinite?(_), do: false

  # Liquid converts native floats to BigDecimal via the float's string form so
  # that arithmetic preserves the human-readable value (`9.99` stays `9.99`).
  defp to_decimal(%Decimal{} = d), do: d
  defp to_decimal(n) when is_integer(n), do: Decimal.new(n)
  defp to_decimal(n) when is_float(n), do: n |> Float.to_string() |> Decimal.new()

  defp dec_zero?(%Decimal{coef: 0}), do: true
  defp dec_zero?(%Decimal{}), do: false
  defp dec_zero?(n) when is_integer(n) or is_float(n), do: n == 0

  defp non_integer_zero?(0), do: false
  defp non_integer_zero?(n) when is_integer(n), do: false
  defp non_integer_zero?(n) when is_float(n), do: n == 0
  defp non_integer_zero?(%Decimal{coef: 0}), do: true
  defp non_integer_zero?(_), do: false

  # ---- Arithmetic ---------------------------------------------------------

  def add(a, b) when is_integer(a) and is_integer(b), do: a + b
  def add(a, b), do: with_ctx(fn -> Decimal.add(to_decimal(a), to_decimal(b)) end)

  def sub(a, b) when is_integer(a) and is_integer(b), do: a - b
  def sub(a, b), do: with_ctx(fn -> Decimal.sub(to_decimal(a), to_decimal(b)) end)

  def mul(a, b) when is_integer(a) and is_integer(b), do: a * b
  def mul(a, b), do: with_ctx(fn -> Decimal.mult(to_decimal(a), to_decimal(b)) end)

  # Liquid's `Integer#/` is floor division (`-7 / 4 == -2`). For mixed int/
  # float operations Liquid coerces both to BigDecimal, so any non-integer
  # operand routes through Decimal -- which handles 0.0 divisors as a
  # sign-preserving Infinity automatically.
  def divide(a, b) when is_integer(a) and is_integer(b) do
    if b == 0, do: {:zero_division}, else: Integer.floor_div(a, b)
  end

  def divide(a, b) do
    cond do
      # Liquid renders finite / infinity as 0.0 (Float), not Decimal "0".
      infinite?(b) and not special?(a) -> 0.0
      true -> with_ctx(fn -> Decimal.div(to_decimal(a), to_decimal(b)) end)
    end
  end

  # Ruby's `%` is `a - b * floor(a / b)` (sign matches divisor). Decimal.rem
  # uses truncation, so we implement floor-mod manually for non-integers.
  def modulo(a, b) when is_integer(a) and is_integer(b) do
    if b == 0, do: {:zero_division}, else: Integer.mod(a, b)
  end

  def modulo(a, b) do
    cond do
      nan?(a) or nan?(b) ->
        nan()

      infinite?(a) ->
        nan()

      infinite?(b) ->
        # Liquid renders `finite mod infinity` as the value coerced to Float
        # (`10` -> `10.0`, `10.5` -> `10.5`).
        finite_as_float(a)

      non_integer_zero?(b) ->
        nan()

      dec_zero?(b) ->
        {:zero_division}

      true ->
        with_ctx(fn ->
          q = to_decimal(a) |> Decimal.div(to_decimal(b)) |> dec_floor()
          Decimal.sub(to_decimal(a), Decimal.mult(to_decimal(b), q))
        end)
    end
  end

  defp finite_as_float(n) when is_integer(n), do: n * 1.0
  defp finite_as_float(n) when is_float(n), do: n
  defp finite_as_float(%Decimal{} = d), do: Decimal.to_float(d)

  defp dec_floor(%Decimal{coef: c} = d) when c in [:inf, :NaN, :qNaN, :sNaN], do: d
  defp dec_floor(%Decimal{} = d), do: Decimal.round(d, 0, :floor)

  def negate(n) when is_integer(n), do: -n
  def negate(n) when is_float(n), do: -n
  def negate(%Decimal{} = d), do: Decimal.negate(d)

  def absolute(n) when is_integer(n), do: abs(n)
  def absolute(n) when is_float(n), do: abs(n)
  def absolute(%Decimal{} = d), do: Decimal.abs(d)

  # ---- Comparison ---------------------------------------------------------

  # `Decimal.compare/2` returns `:lt | :eq | :gt`, or a NaN Decimal if the
  # comparison is unordered. We collapse the NaN case to the `:nan` atom for
  # uniformity with the apply_op dispatch below.
  def compare(a, b) do
    cond do
      nan?(a) or nan?(b) ->
        :nan

      is_number(a) and is_number(b) ->
        cond do
          a < b -> :lt
          a > b -> :gt
          true -> :eq
        end

      true ->
        with_ctx(fn ->
          case Decimal.compare(to_decimal(a), to_decimal(b)) do
            :lt -> :lt
            :gt -> :gt
            :eq -> :eq
          end
        end)
    end
  end

  # Apply a Liquid comparison op (:==, :!=, :<, :>, :<=, :>=) to two operands
  # when at least one is special / Decimal.
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
  def computation_error(%Decimal{coef: :inf, sign: 1}),
    do: "Liquid error: Computation results in 'Infinity'"

  def computation_error(%Decimal{coef: :inf, sign: -1}),
    do: "Liquid error: Computation results in '-Infinity'"

  def computation_error(%Decimal{coef: c}) when c in [:NaN, :qNaN, :sNaN],
    do: "Liquid error: Computation results in 'NaN' (Not a Number)"
end
