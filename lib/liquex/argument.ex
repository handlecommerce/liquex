defmodule Liquex.Argument do
  @moduledoc false

  alias Liquex.Context
  alias Liquex.Indifferent
  alias Liquex.Resolver

  @type field_t :: any
  @type argument_t ::
          {:field, [field_t]}
          | {:literal, field_t}
          | {:inclusive_range, [begin: field_t, end: field_t]}

  @spec eval(argument_t | [argument_t], Context.t()) :: {field_t, Context.t()}
  def eval([argument], context), do: eval(argument, context)

  def eval({:field, accesses}, %Context{} = context),
    do: do_eval(context, accesses, context)

  def eval({:literal, literal}, context), do: {literal, context}

  def eval({:inclusive_range, [begin: begin_value, end: end_value]}, context) do
    # Liquid range bounds are coerced via Ruby's `to_i`, and the range only
    # iterates forward -- `(5..1)` yields nothing while still printing "5..1".
    # Use Range.new(.., .., 1) so the struct preserves the original endpoints
    # but `Enum.to_list/1` returns [] when first > last.
    {b, context} = eval(begin_value, context)
    {e, context} = eval(end_value, context)
    {Range.new(to_int(b), to_int(e), 1), context}
  end

  def eval({:keyword, [key, value]}, context) do
    {value, context} = eval(value, context)
    {{key, value}, context}
  end

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
  defp do_eval(nil, _, context), do: {nil, context}

  # Special case ".first"
  defp do_eval(value, [{:key, "first"} | tail], context) when is_list(value) do
    {next, context} = value |> Enum.at(0) |> apply_lazy(value, context)
    do_eval(next, tail, context)
  end

  # Special case ".last"
  defp do_eval(value, [{:key, "last"} | tail], context) when is_list(value) do
    {next, context} = value |> List.last() |> apply_lazy(value, context)
    do_eval(next, tail, context)
  end

  # Special case ".size"
  defp do_eval(value, [{:key, "size"} | tail], context) when is_binary(value),
    do: do_eval(String.length(value), tail, context)

  defp do_eval(value, [{:key, "size"} | tail], context) when is_list(value),
    do: do_eval(length(value), tail, context)

  # Strings only respond to `size` -- `.first`/`.last`/anything else is nil,
  # matching plain Ruby (where `Access.fetch/2` would raise for binaries).
  defp do_eval(value, [{:key, _} | _tail], context) when is_binary(value),
    do: {nil, context}

  defp do_eval(value, [{:key, key} | tail], context) do
    {result, context} = Resolver.fetch(value, key, context)

    case result do
      {:ok, next} ->
        {next, context} = apply_lazy(next, value, context)
        do_eval(next, tail, context)

      :error ->
        context = report_undefined(context, key)
        do_eval(nil, tail, context)
    end
  end

  defp do_eval(value, [{:accessor, accessor} | tail], context) do
    {next, context} = value_at(value, accessor, context)
    {next, context} = apply_lazy(next, value, context)
    do_eval(next, tail, context)
  end

  defp report_undefined(%Context{strict_variables: true} = context, key) do
    Context.report_error(context, Liquex.Error.render_error("Undefined variable: #{key}"))
  end

  defp report_undefined(context, _key), do: context

  defp value_at(value, argument, context) when is_tuple(argument) and is_map(value) do
    {key, context} = eval(argument, context)
    Resolver.get(value, key, nil, context)
  end

  defp value_at(value, argument, context) when is_tuple(argument) and is_list(value) do
    {idx, context} = eval(argument, context)
    {Enum.at(value, idx), context}
  end

  defp value_at(_value, _index, context), do: {[], context}

  # Apply a lazy function if needed
  defp apply_lazy(fun, _parent, context) when is_function(fun, 0), do: {fun.(), context}
  defp apply_lazy(fun, parent, context) when is_function(fun, 1), do: {fun.(parent), context}
  defp apply_lazy(value, _, context), do: {value, context}

  def assign(context, [argument], value), do: assign(context, argument, value)

  def assign(%Context{} = context, {:field, accesses}, value),
    do: do_assign(context, accesses, value)

  # Top-level assigns into a Context preserve the Context struct by routing
  # through `Context.assign/3` rather than demoting to a plain map.
  defp do_assign(%Context{} = ctx, [{:key, key}], value),
    do: Context.assign(ctx, key, value)

  defp do_assign(%Context{} = ctx, [{:key, key} | tail], value) do
    inner = Context.get(ctx, key) || %{}
    Context.assign(ctx, key, do_assign(inner, tail, value))
  end

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
