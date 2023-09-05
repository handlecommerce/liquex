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
    do: do_eval(context, accesses, context) |> strip_cache_key()

  def eval({:literal, literal}, context), do: {literal, context}

  def eval({:inclusive_range, [begin: begin_value, end: end_value]}, context) do
    {evaled_begin_value, context} = eval(begin_value, context)
    {evaled_end_value, context} = eval(end_value, context)
    {evaled_begin_value..evaled_end_value, context}
  end

  def eval({:keyword, [key, value]}, context) do
    {evaled_value, context} = eval(value, context)

    {{key, evaled_value}, context}
  end

  defp do_eval(value, [], context), do: apply_lazy(value, nil, context)
  defp do_eval(nil, _, context), do: {nil, context}

  # Special case ".first"
  defp do_eval(value, [{:key, "first"} = cache_key | tail], context) when is_list(value) do
    context = add_to_cache_key(context, cache_key)

    value
    |> Enum.at(0)
    |> apply_lazy(value, context)
    |> then(fn {value, context} -> do_eval(value, tail, context) end)
  end

  # Special case ".last"
  defp do_eval(value, [{:key, "last"} = cache_key | tail], context) when is_list(value) do
    context = add_to_cache_key(context, cache_key)

    value
    |> List.last()
    |> apply_lazy(value, context)
    |> then(fn {value, context} -> do_eval(value, tail, context) end)
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

  defp do_eval(value, [{:key, key} = cache_key | tail], context) do
    context = add_to_cache_key(context, cache_key)

    value
    |> Indifferent.get(key)
    |> apply_lazy(value, context)
    |> then(fn {value, context} -> do_eval(value, tail, context) end)
  end

  defp do_eval(value, [{:accessor, accessor} = cache_key | tail], context) do
    context = add_to_cache_key(context, cache_key)

    value
    |> value_at(accessor, context)
    |> then(fn {child_value, context} -> apply_lazy(child_value, value, context) end)
    |> then(fn {value, context} -> do_eval(value, tail, context) end)
  end

  defp value_at(value, argument, context) when is_tuple(argument) and is_map(value) do
    {evalued_argument, context} = eval(argument, context)

    {Indifferent.get(value, evalued_argument), context}
  end

  defp value_at(value, argument, context) when is_tuple(argument) and is_list(value) do
    {evalued_argument, context} = eval(argument, context)

    {Enum.at(value, evalued_argument), context}
  end

  defp value_at(_value, _index, context), do: {[], context}

  # Apply a lazy function if needed
  defp apply_lazy(fun, _parent, context) when is_function(fun, 0), do: {fun.(), context}
  defp apply_lazy(fun, parent, context) when is_function(fun, 1), do: {fun.(parent), context}

  defp apply_lazy(fun, parent, context) when is_function(fun, 2) do
    fun.(parent, context)
    |> case do
      {value, %Context{} = context} ->
        {value, context}

      value ->
        {value, context}
    end
  end

  defp apply_lazy(value, _, context), do: {value, context}

  defp strip_cache_key({value, context}),
    do:
      {value,
       Map.put(
         context,
         :render_state,
         Map.put(context.render_state, :cache_key, [])
       )}

  defp add_to_cache_key(context, key) do
    context = Map.put_new(context, :render_state, %{})

    Map.put(
      context,
      :render_state,
      Map.put(context.render_state, :cache_key, (context.render_state[:cache_key] || []) ++ [key])
    )
  end

  def assign(context, [argument], value), do: assign(context, argument, value)

  def assign(%Context{} = context, {:field, accesses}, value),
    do: do_assign(context, accesses, value)

  defp do_assign(variables, [{:key, key} | tail], value) do
    case tail do
      [] ->
        Indifferent.put(variables, key, value)

      _ ->
        existing_value = Indifferent.get(variables, key, %{})
        updated_value = do_assign(existing_value, tail, value)
        Indifferent.put(variables, key, updated_value)
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
