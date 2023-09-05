defmodule Liquex.Expression do
  @moduledoc false

  alias Liquex.Argument
  alias Liquex.Context

  alias Liquex.Collection

  @spec eval(maybe_improper_list | {:field, any} | {:literal, any}, Context.t()) :: any
  def eval([left: left, op: op, right: right], %Context{} = context) do
    {left_evaled, context} = Argument.eval(left, context)
    {right_evaled, context} = Argument.eval(right, context)

    {do_eval({
       left_evaled,
       op,
       right_evaled
     }), context}
  end

  def eval({type, _} = argument, context) when type in [:field, :literal] do
    {evaled, context} = Argument.eval([argument], context)
    {do_eval(evaled), context}
  end

  def eval(expressions, context) when is_list(expressions) do
    expressions
    |> Enum.chunk_every(2)
    |> Enum.reverse()
    |> Enum.reduce({nil, context}, fn
      [exp, :and], {acc, context} ->
        {evaled, context} = eval(exp, context)
        {evaled and acc, context}

      [exp, :or], {acc, context} ->
        {evaled, context} = eval(exp, context)
        {evaled or acc, context}

      [exp], {nil, context} ->
        eval(exp, context)
    end)
  end

  defp do_eval({left, :<=, nil}) when is_number(left), do: false
  defp do_eval({left, :<, nil}) when is_number(left), do: false
  defp do_eval({nil, :>=, right}) when is_number(right), do: false
  defp do_eval({nil, :>, right}) when is_number(right), do: false
  defp do_eval({nil, :contains, _right}), do: false
  defp do_eval({_, :contains, nil}), do: false
  defp do_eval({left, :contains, right}) when is_list(left), do: right in left

  defp do_eval({left, :contains, right}),
    do: String.contains?(to_string(left), to_string(right))

  defp do_eval({left, op, right}), do: apply(Kernel, op, [left, right])

  # Truthy values
  defp do_eval(nil), do: false
  defp do_eval(false), do: false
  defp do_eval(_), do: true

  @spec eval_collection(Collection.t(), Keyword.t()) :: Collection.t()
  def eval_collection(collection, parameters \\ [])
  def eval_collection(collection, []), do: collection

  def eval_collection(collection, [{:limit, limit} | tail]),
    do: collection |> Collection.limit(limit) |> eval_collection(tail)

  def eval_collection(collection, [{:offset, offset} | tail]),
    do: collection |> Collection.offset(offset) |> eval_collection(tail)

  def eval_collection(collection, [{:order, :reversed} | tail]),
    do: collection |> Collection.reverse() |> eval_collection(tail)

  def eval_collection(collection, [{:cols, _} | tail]),
    do: collection |> eval_collection(tail)
end
