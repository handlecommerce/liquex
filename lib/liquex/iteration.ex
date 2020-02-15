defmodule Liquex.Iteration do
  alias Liquex.Argument

  def render(
        [
          for: [
            identifier: identifier,
            collection: collection,
            parameters: parameters,
            contents: contents
          ]
        ],
        context
      ) do
    result =
      collection
      |> Argument.eval(context)
      |> eval(parameters)
      |> Enum.map(fn p ->
        contents
        |> Liquex.render(Map.put(context, identifier, p))
        |> elem(0)
      end)

    {result, context}
  end

  defp eval(collection, []), do: collection

  defp eval(collection, [{:limit, limit} | tail]),
    do: collection |> Enum.take(limit) |> eval(tail)

  defp eval(collection, [{:offset, offset} | tail]),
    do: collection |> Enum.drop(offset) |> eval(tail)

  defp eval(collection, [{:order, :reversed} | tail]),
    do: collection |> Enum.reverse() |> eval(tail)
end
