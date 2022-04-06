defmodule Liquex.Render.Iteration do
  @moduledoc false

  alias Liquex.Argument
  alias Liquex.Collection
  alias Liquex.Context

  @behaviour Liquex.Render

  @impl Liquex.Render
  @spec render(any, Context.t()) :: {iodata, Context.t()}
  def render({:iteration, tag}, context), do: do_render(tag, context)
  def render(_, _), do: false

  defp do_render([for: for_statement], %Context{} = context),
    do: do_render([for: for_statement, else: [contents: []]], context)

  defp do_render(
         [
           for: [
             identifier: identifier,
             collection: collection,
             parameters: parameters,
             contents: contents
           ],
           else: [contents: else_contents]
         ],
         %Context{} = context
       ) do
    collection
    |> Argument.eval(context)
    |> eval_modifiers(parameters)
    |> Collection.to_enumerable()
    |> render_collection(identifier, contents, else_contents, context)
  end

  defp do_render([tag], context) when tag in [:break, :continue],
    do: throw({tag, context})

  defp do_render(
         [
           tablerow: [
             identifier: identifier,
             collection: collection,
             parameters: parameters,
             contents: contents
           ]
         ],
         context
       ) do
    cols = Keyword.get(parameters, :cols, 1)

    collection
    |> Argument.eval(context)
    |> eval_modifiers(parameters)
    |> Collection.to_enumerable()
    |> render_row(identifier, contents, cols, context)
  end

  defp do_render(_, _), do: false

  defp eval_modifiers(collection, []), do: collection

  defp eval_modifiers(collection, [{:limit, limit} | tail]),
    do: collection |> Collection.limit(limit) |> eval_modifiers(tail)

  defp eval_modifiers(collection, [{:offset, offset} | tail]),
    do: collection |> Collection.offset(offset) |> eval_modifiers(tail)

  defp eval_modifiers(collection, [{:order, :reversed} | tail]),
    do: collection |> Collection.reverse() |> eval_modifiers(tail)

  defp eval_modifiers(collection, [{:cols, _} | tail]),
    do: collection |> eval_modifiers(tail)

  defp render_collection(nil, _, _, contents, context),
    do: Liquex.render(contents, context)

  defp render_collection([], _, _, contents, context),
    do: Liquex.render(contents, context)

  defp render_collection(results, identifier, contents, _, context) do
    forloop_init = Map.get(context.variables, "forloop")
    len = Enum.count(results)

    {result, context} =
      results
      |> Enum.with_index(0)
      |> Enum.reduce({[], context}, fn {record, index}, {acc, ctx} ->
        try do
          # Assign the loop variables
          ctx =
            ctx
            |> Context.assign("forloop", forloop(index, len))
            |> Context.assign(identifier, record)

          {r, ctx} = Liquex.render(contents, ctx)

          {
            [r | acc],
            Context.assign(ctx, "forloop", forloop_init)
          }
        catch
          {:continue, ctx} ->
            {acc, Context.assign(ctx, "forloop", forloop_init)}

          {:break, ctx} ->
            throw({:result, acc, Context.assign(ctx, "forloop", forloop_init)})
        end
      end)

    {Enum.reverse(result), context}
  catch
    {:result, result, context} ->
      # credo:disable-for-next-line
      {Enum.reverse(result), context}
  end

  defp render_row(collection, identifier, contents, cols, context) do
    {results, context} =
      collection
      |> Enum.with_index()
      |> Enum.reduce({[], context}, fn {record, idx}, {acc, ctx} ->
        ctx = Context.assign(ctx, identifier, record)

        {result, ctx} = Liquex.render(contents, ctx)

        result =
          cond do
            cols == 1 ->
              ["<tr><td>", result, "</td></tr>"]

            rem(idx, cols) == 0 ->
              ["<tr><td>", result, "</td>"]

            rem(idx, cols) == cols - 1 ->
              ["<td>", result, "</td></tr>"]

            true ->
              ["<td>", result, "</td>"]
          end

        {[result | acc], ctx}
      end)

    # Close out the table
    closing =
      0..rem(length(collection), cols)
      |> Enum.drop(1)
      |> Enum.map(fn _ -> "<td></td>" end)
      |> case do
        [] -> []
        tags -> ["</tr>" | tags]
      end

    {Enum.reverse(closing ++ results), context}
  end

  defp forloop(index, length) do
    %{
      "index" => index + 1,
      "index0" => index,
      "rindex" => length - index,
      "rindex0" => length - index - 1,
      "first" => index == 0,
      "last" => index == length - 1,
      "length" => length
    }
  end
end
