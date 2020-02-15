defmodule Liquex.Render.Iteration do
  alias Liquex.Argument
  alias Liquex.Context

  def render(
        [
          for: [
            identifier: identifier,
            collection: collection,
            parameters: parameters,
            contents: contents
          ]
        ],
        %Context{} = context
      ) do
    result =
      collection
      |> Argument.eval(context)
      |> eval_modifiers(parameters)
      |> Enum.map(fn p ->
        contents
        |> Liquex.render(Context.assign(context, identifier, p))
        |> elem(0)
      end)

    {result, context}
  end

  defp eval_modifiers(collection, []), do: collection

  defp eval_modifiers(collection, [{:limit, limit} | tail]),
    do: collection |> Enum.take(limit) |> eval_modifiers(tail)

  defp eval_modifiers(collection, [{:offset, offset} | tail]),
    do: collection |> Enum.drop(offset) |> eval_modifiers(tail)

  defp eval_modifiers(collection, [{:order, :reversed} | tail]),
    do: collection |> Enum.reverse() |> eval_modifiers(tail)
end
