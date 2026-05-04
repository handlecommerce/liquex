defmodule Liquex.Render do
  @moduledoc false

  alias Liquex.Context

  @callback render({atom, any}, Context.t()) :: {iodata, Context.t()} | iodata | false

  @type result_t ::
          {iodata(), Context.t()}
          | {:break, iodata(), Context.t()}
          | {:continue, iodata(), Context.t()}

  @spec render!(iodata(), Liquex.document_t(), Context.t()) :: result_t

  @doc """
  Renders a Liquid AST `document` into an `iodata`

  A `context` is given to handle temporary contextual information for
  this render.
  """
  def render!(content, [], context),
    do: {content |> Enum.reverse(), context}

  def render!(content, [tag | tail], %Context{} = context) do
    case do_render(tag, context) do
      # No tag renderer found
      nil ->
        raise Liquex.Error, "No tag renderer found for tag #{tag}"

      {:break, result, context} ->
        {:break, [result | content], context}

      {:continue, result, context} ->
        {:continue, [result | content], context}

      # Returned the rendered results and new context
      {result, %Context{} = context} ->
        render!([result | content], tail, context)
    end
  end

  def render!(document, %Context{} = context), do: render!([], document, context)

  defp do_render({:text, text}, context), do: {text, context}

  defp do_render({{:tag, module}, contents}, context) when is_atom(module),
    do: module.render(contents, context)

  @doc """
  Renders a Liquid value as a string for `{{ }}` / `echo` output. Matches
  Liquid's behavior of stringifying list elements and concatenating with no
  separator (`[1, 2, 3]` -> `"123"`). Decimals are rendered via the float
  shortest-round-trip form so `Decimal.new("24.49")` renders as `"24.49"`,
  matching Ruby's `BigDecimal#to_f` -> `Float#to_s`.
  """
  @spec to_output_string(any) :: binary
  def to_output_string(value) when is_list(value),
    do: Enum.map_join(value, "", &to_output_string/1)

  def to_output_string(nil), do: ""

  # NaN's sign is not meaningful (-NaN == NaN), but Decimal.sub etc. can
  # produce a negative NaN. Render as "NaN" regardless of sign to match Ruby's
  # `Float::NAN.to_s` -> "NaN".
  def to_output_string(%Decimal{coef: c}) when c in [:NaN, :qNaN, :sNaN], do: "NaN"

  def to_output_string(%Decimal{coef: :inf} = d), do: Decimal.to_string(d)

  def to_output_string(%Decimal{} = d),
    do: d |> Decimal.to_float() |> ruby_float_format()

  def to_output_string(value) when is_float(value), do: ruby_float_format(value)

  def to_output_string(first..last//_), do: "#{first}..#{last}"

  def to_output_string(map) when is_map(map) and not is_struct(map),
    do: inspect_value(map)

  def to_output_string(value), do: to_string(value)

  # Ruby's Object#inspect for values rendered inside a hash literal:
  # `{"a"=>nil, "b"=>[1, 2]}`. Used recursively for nested structures.
  defp inspect_value(nil), do: "nil"
  defp inspect_value(true), do: "true"
  defp inspect_value(false), do: "false"
  defp inspect_value(s) when is_binary(s), do: inspect(s)
  defp inspect_value(n) when is_integer(n) or is_float(n), do: to_string(n)
  defp inspect_value(%Decimal{} = d), do: to_output_string(d)
  defp inspect_value(first..last//_), do: "#{first}..#{last}"

  defp inspect_value(list) when is_list(list),
    do: "[" <> Enum.map_join(list, ", ", &inspect_value/1) <> "]"

  defp inspect_value(map) when is_map(map) and not is_struct(map) do
    body =
      Enum.map_join(map, ", ", fn {k, v} ->
        "#{inspect_value(k)}=>#{inspect_value(v)}"
      end)

    "{" <> body <> "}"
  end

  defp inspect_value(value), do: to_string(value)

  # Ruby's Float#to_s rules: decimal notation when the magnitude is in
  # [1e-4, 1e15); scientific otherwise. Scientific form is always
  # `D.DDDe<sign><2+digit-exponent>` (e.g. `1.0e+15`, `1.0e-05`). Elixir's
  # `Float.to_string/1` uses different thresholds and exponent format, so we
  # normalize the digits and re-render to match byte-for-byte.
  defp ruby_float_format(+0.0), do: "0.0"
  defp ruby_float_format(-0.0), do: "-0.0"

  defp ruby_float_format(f) when is_float(f) do
    {sign, digits, exp} = decompose_float(f)

    if exp >= -4 and exp <= 14 do
      format_decimal(sign, digits, exp)
    else
      format_scientific(sign, digits, exp)
    end
  end

  defp decompose_float(f) do
    s = Float.to_string(f)

    {sign, rest} =
      case s do
        "-" <> r -> {"-", r}
        _ -> {"", s}
      end

    case String.split(rest, "e") do
      [num] -> decompose_decimal(sign, num)
      [num, exp_str] -> decompose_scientific(sign, num, String.to_integer(exp_str))
    end
  end

  defp decompose_decimal(sign, num) do
    [int_part, frac_part] = String.split(num, ".")
    all_digits = int_part <> frac_part
    trimmed = String.trim_leading(all_digits, "0")

    if trimmed == "" do
      {sign, "0", 0}
    else
      leading_zeros = byte_size(all_digits) - byte_size(trimmed)
      exp = byte_size(int_part) - leading_zeros - 1
      digits = strip_trailing_zeros(trimmed)
      {sign, digits, exp}
    end
  end

  defp decompose_scientific(sign, num, exp_offset) do
    [int_part, frac_part] = String.split(num, ".")
    digits = strip_trailing_zeros(int_part <> frac_part)
    {sign, digits, exp_offset}
  end

  defp strip_trailing_zeros(digits) do
    case String.trim_trailing(digits, "0") do
      "" -> "0"
      stripped -> stripped
    end
  end

  defp format_decimal(sign, digits, exp) when exp >= 0 do
    n = byte_size(digits)

    if exp + 1 >= n do
      sign <> digits <> String.duplicate("0", exp + 1 - n) <> ".0"
    else
      {int_str, frac_str} = String.split_at(digits, exp + 1)
      sign <> int_str <> "." <> frac_str
    end
  end

  defp format_decimal(sign, digits, exp) when exp < 0 do
    sign <> "0." <> String.duplicate("0", -exp - 1) <> digits
  end

  defp format_scientific(sign, digits, exp) do
    mantissa =
      case digits do
        <<d::utf8>> -> <<d::utf8>> <> ".0"
        <<d::utf8, rest::binary>> -> <<d::utf8>> <> "." <> rest
      end

    exp_str =
      if exp >= 0 do
        "+" <> String.pad_leading(Integer.to_string(exp), 2, "0")
      else
        "-" <> String.pad_leading(Integer.to_string(-exp), 2, "0")
      end

    sign <> mantissa <> "e" <> exp_str
  end

  @spec apply_filters(any, [Liquex.Filter.filter_t()], Context.t()) :: {any, Context.t()}
  def apply_filters(value, filters, %Context{} = context),
    do: Enum.reduce(filters, {value, context}, &apply_filter/2)

  defp apply_filter(filter, {value, %Context{filter_module: filter_module} = context}) do
    case filter_module.apply(value, filter, context) do
      {new_value, %Context{} = new_context} -> {new_value, new_context}
      new_value -> {new_value, context}
    end
  rescue
    # Route "unknown filter" errors through the context's :error_mode.
    # Filter implementations that deliberately raise `Liquex.Error` (e.g. a
    # filter rejecting bad arguments) propagate as before.
    UndefinedFunctionError ->
      name = Liquex.Filter.filter_name(filter)
      hint = Liquex.Filter.did_you_mean(name, context.filter_module)
      err = Liquex.Error.render_error("Invalid filter #{name}#{hint}")
      {value, Context.report_error(context, err)}
  end
end
