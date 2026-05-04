defmodule Liquex.Expression do
  @moduledoc false

  alias Liquex.Argument
  alias Liquex.Context

  alias Liquex.Collection

  @spec eval(maybe_improper_list | {:field, any} | {:literal, any}, Context.t()) ::
          {any, Context.t()}
  def eval([left: left, op: op, right: right], %Context{} = context) do
    {l, context} = Argument.eval(left, context)
    {r, context} = Argument.eval(right, context)
    {do_eval({l, op, r}), context}
  end

  def eval({type, _} = argument, context) when type in [:field, :literal] do
    {value, context} = Argument.eval([argument], context)
    {do_eval(value), context}
  end

  def eval(expressions, context) when is_list(expressions) do
    expressions
    |> Enum.chunk_every(2)
    |> Enum.reverse()
    |> Enum.reduce({nil, context, :init}, fn
      [exp, :and], {acc, ctx, :ready} ->
        {v, ctx} = eval(exp, ctx)
        {v and acc, ctx, :ready}

      [exp, :or], {acc, ctx, :ready} ->
        {v, ctx} = eval(exp, ctx)
        {v or acc, ctx, :ready}

      [exp], {nil, ctx, :init} ->
        {v, ctx} = eval(exp, ctx)
        {v, ctx, :ready}
    end)
    |> case do
      {value, ctx, _} -> {value, ctx}
    end
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

  defp do_eval({%Liquex.Special{} = s, :==, right}), do: Liquex.Special.equal?(s, right)
  defp do_eval({left, :==, %Liquex.Special{} = s}), do: Liquex.Special.equal?(s, left)
  defp do_eval({%Liquex.Special{} = s, :!=, right}), do: not Liquex.Special.equal?(s, right)
  defp do_eval({left, :!=, %Liquex.Special{} = s}), do: not Liquex.Special.equal?(s, left)

  defp do_eval({left, op, right})
       when is_struct(left, Decimal) or is_struct(right, Decimal),
       do: Liquex.Math.apply_op(op, left, right)

  defp do_eval({left, op, right}), do: apply(Kernel, op, [left, right])

  # Truthy values
  defp do_eval(nil), do: false
  defp do_eval(false), do: false
  defp do_eval(_), do: true

  @spec eval_collection(Collection.t(), Keyword.t()) :: Collection.t()
  def eval_collection(collection, parameters \\ [])
  def eval_collection(nil, _), do: nil

  def eval_collection(collection, parameters) do
    # Liquid applies offset then limit regardless of declared order, then
    # reverses last. Match that fixed order so output is independent of how
    # the user spelled the parameters.
    collection
    |> apply_offset(parameters)
    |> apply_limit(parameters)
    |> apply_reverse(parameters)
  end

  defp apply_offset(collection, parameters) do
    case Keyword.get(parameters, :offset) do
      nil -> collection
      n -> Collection.offset(collection, n)
    end
  end

  defp apply_limit(collection, parameters) do
    case Keyword.get(parameters, :limit) do
      nil -> collection
      n -> Collection.limit(collection, n)
    end
  end

  defp apply_reverse(collection, parameters) do
    case Keyword.get(parameters, :order) do
      :reversed -> Collection.reverse(collection)
      _ -> collection
    end
  end
end
