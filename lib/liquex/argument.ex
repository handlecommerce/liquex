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

  def eval({:field, accesses}, %Context{variables: variables}),
    do: do_eval(variables, accesses)

  def eval({:literal, literal}, _context), do: literal

  def eval({:inclusive_range, [begin: begin_value, end: end_value]}, context),
    do: eval(begin_value, context)..eval(end_value, context)

  def eval({:keyword, [key, value]}, context), do: {key, eval(value, context)}

  defp do_eval(value, []), do: apply_lazy(value, nil)
  defp do_eval(nil, _), do: nil

  # Special case ".first"
  defp do_eval(value, [{:key, "first"} | tail]) when is_list(value) do
    value
    |> Enum.at(0)
    |> apply_lazy(value)
    |> do_eval(tail)
  end

  # Special case ".size"
  defp do_eval(value, [{:key, "size"} | tail]) when is_list(value) do
    value
    |> length()
    |> do_eval(tail)
  end

  defp do_eval(value, [{:key, key} | tail]) do
    value
    |> Indifferent.get(key)
    |> apply_lazy(value)
    |> do_eval(tail)
  end

  defp do_eval(value, [{:accessor, accessor} | tail]) do
    value
    |> Enum.at(accessor)
    |> apply_lazy(value)
    |> do_eval(tail)
  end

  # Apply a lazy function if needed
  defp apply_lazy(fun, _parent) when is_function(fun, 0), do: fun.()
  defp apply_lazy(fun, parent) when is_function(fun, 1), do: fun.(parent)

  defp apply_lazy(value, _), do: value

  def assign(context, [argument], value), do: assign(context, argument, value)

  def assign(%Context{variables: variables} = context, {:field, accesses}, value),
    do: %{context | variables: do_assign(variables, accesses, value)}

  defp do_assign(variables, [{:key, key} | tail], value) do
    case tail do
      [] -> Map.put(variables, key, value)
      _ -> Map.update(variables, key, nil, &do_assign(&1, tail, value))
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
  defp do_assign(_, _, _), do: raise(LiquexError, "Could not assign value")
end
