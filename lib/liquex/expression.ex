defmodule Liquex.Expression do
  alias Liquex.Argument

  def eval({left, op, right}, context) do
    do_eval({
      left |> Argument.eval(context),
      op,
      right |> Argument.eval(context)
    })
  end

  def eval({type, _} = argument, context) when type in [:field, :literal],
    do: argument |> Argument.eval(context) |> do_eval()

  def eval(expressions, context) when is_list(expressions) do
    expressions
    |> Enum.chunk_every(2)
    |> Enum.reverse()
    |> Enum.reduce(nil, fn
      [exp, :and], acc ->
        eval(exp, context) and acc

      [exp, :or], acc ->
        eval(exp, context) or acc

      [exp], nil ->
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

  defp do_eval({left, :contains, right}) when is_binary(left) and is_binary(right),
    do: String.contains?(left, right)

  defp do_eval({left, op, right}), do: apply(Kernel, op, [left, right])

  # Truthy values
  defp do_eval(nil), do: false
  defp do_eval(false), do: false
  defp do_eval(_), do: true
end
