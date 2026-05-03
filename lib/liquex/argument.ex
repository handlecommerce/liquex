defmodule Liquex.Argument do
  @moduledoc false

  alias Liquex.Context
  alias Liquex.Indifferent

  @type field_t :: any
  @type argument_t ::
          {:field, [field_t]}
          | {:literal, field_t}
          | {:inclusive_range, [begin: field_t, end: field_t]}

  @spec eval(argument_t | [argument_t], Context.t()) :: field_t
  def eval([argument], context), do: eval(argument, context)

  def eval({:field, accesses}, %Context{} = context),
    do: do_eval(context, accesses, context)

  def eval({:literal, literal}, _context), do: literal

  def eval({:inclusive_range, [begin: begin_value, end: end_value]}, context) do
    # Liquid range bounds are coerced via Ruby's `to_i`, and the range only
    # iterates forward -- `(5..1)` yields nothing while still printing "5..1".
    # Use Range.new(.., .., 1) so the struct preserves the original endpoints
    # but `Enum.to_list/1` returns [] when first > last.
    Range.new(to_int(eval(begin_value, context)), to_int(eval(end_value, context)), 1)
  end

  def eval({:keyword, [key, value]}, context), do: {key, eval(value, context)}

  defp to_int(n) when is_integer(n), do: n
  defp to_int(n) when is_float(n), do: trunc(n)
  defp to_int(%Decimal{} = d), do: d |> Decimal.round(0, :down) |> Decimal.to_integer()

  defp to_int(s) when is_binary(s) do
    case Integer.parse(s) do
      {n, _} -> n
      :error -> 0
    end
  end

  defp to_int(_), do: 0

  defp do_eval(value, [], context), do: apply_lazy(value, nil, context)
  defp do_eval(nil, _, _context), do: nil

  # Special case ".first"
  defp do_eval(value, [{:key, "first"} | tail], context) when is_list(value) do
    value
    |> Enum.at(0)
    |> apply_lazy(value, context)
    |> do_eval(tail, context)
  end

  # Special case ".last"
  defp do_eval(value, [{:key, "last"} | tail], context) when is_list(value) do
    value
    |> List.last()
    |> apply_lazy(value, context)
    |> do_eval(tail, context)
  end

  # Special case ".size"
  defp do_eval(value, [{:key, "size"} | tail], context) when is_binary(value) do
    value
    |> String.length()
    |> do_eval(tail, context)
  end

  defp do_eval(value, [{:key, "size"} | tail], context) when is_list(value) do
    value
    |> length()
    |> do_eval(tail, context)
  end

  # Strings only respond to `size` -- `.first`/`.last`/anything else is nil,
  # matching plain Ruby (where `Access.fetch/2` would raise for binaries).
  defp do_eval(value, [{:key, _} | _tail], _context) when is_binary(value), do: nil

  defp do_eval(value, [{:key, key} | tail], context) do
    value
    |> Indifferent.get(key)
    |> apply_lazy(value, context)
    |> do_eval(tail, context)
  end

  defp do_eval(value, [{:accessor, accessor} | tail], context) do
    value
    |> value_at(accessor, context)
    |> apply_lazy(value, context)
    |> do_eval(tail, context)
  end

  defp value_at(value, argument, context) when is_tuple(argument) and is_map(value),
    do: Indifferent.get(value, eval(argument, context))

  defp value_at(value, argument, context) when is_tuple(argument) and is_list(value),
    do: Enum.at(value, eval(argument, context))

  defp value_at(_value, _index, _context), do: []

  # Apply a lazy function if needed
  defp apply_lazy(fun, _parent, _context) when is_function(fun, 0), do: fun.()
  defp apply_lazy(fun, parent, _context) when is_function(fun, 1), do: fun.(parent)

  defp apply_lazy(value, _, _context), do: value

  def assign(context, [argument], value), do: assign(context, argument, value)

  def assign(%Context{} = context, {:field, accesses}, value),
    do: do_assign(context, accesses, value)

  defp do_assign(variables, [{:key, key} | tail], value) do
    case tail do
      [] -> Indifferent.put(variables, key, value)
      _ -> Indifferent.update(variables, key, nil, &do_assign(&1, tail, value))
    end
  end

  defp do_assign(variables, [{:accessor, index} | tail], value) do
    case tail do
      [] ->
        List.replace_at(variables, index, value)

      _ ->
        value =
          variables
          |> Enum.at(index)
          |> do_assign(tail, value)

        List.replace_at(variables, index, value)
    end
  end

  defp do_assign(_variables, [], value), do: value
  defp do_assign(_, _, _), do: raise(Liquex.Error, "Could not assign value")
end
