defmodule Liquex.Argument do
  def eval({:literal, literal}, _context), do: literal

  def eval({:field, accesses}, context) do
    do_eval(context, accesses)
  end

  defp do_eval(value, []), do: value
  defp do_eval(nil, _), do: nil

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
