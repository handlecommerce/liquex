defmodule Liquex.Argument do
  @moduledoc false

  alias Liquex.Context

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

  defp do_eval(value, []), do: value
  defp do_eval(nil, _), do: nil

  # Special case ".first"
  defp do_eval(value, [{:key, "first"} | tail]) when is_list(value) do
    value
    |> Enum.at(0)
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
    |> Map.get(key)
    |> do_eval(tail)
  end

  defp do_eval(value, [{:accessor, accessor} | tail]) do
    value
    |> Enum.at(accessor)
    |> do_eval(tail)
  end
end
