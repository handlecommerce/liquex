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
    {parameters, context} = eval_for_offset(parameters, context, identifier)

    collection
    |> Argument.eval(context)
    |> eval_modifiers(parameters)
    |> Collection.to_enumerable()
    |> render_collection(identifier, contents, else_contents, context)
  end

  defp do_render([tag], context) when tag in [:break, :continue],
    do: throw({tag, context})

  defp do_render([cycle: [sequence: sequence]], %Context{} = context),
    do: do_render([cycle: [group: sequence, sequence: sequence]], context)

  defp do_render([cycle: [group: group, sequence: sequence]], %Context{cycles: cycles} = context) do
    index = Map.get(cycles, group, 0)

    next_index = rem(index + 1, length(sequence))

    result =
      sequence
      |> Enum.at(index)
      |> Argument.eval(context)

    {result, %{context | cycles: Map.put(cycles, group, next_index)}}
  end

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
    {parameters, context} = eval_tablerow_offset(parameters, context, identifier)

    collection
    |> Argument.eval(context)
    |> eval_modifiers(parameters)
    |> Collection.to_enumerable()
    |> render_row(identifier, contents, cols, context)
  end

  defp do_render(_, _), do: false

  defp maybe_eval_modifier(collection, params, mod) do
    if param = params[mod], do: eval_modifier(collection, {mod, param}), else: collection
  end

  defp eval_modifiers(collection, params) do
    collection
    |> maybe_eval_modifier(params, :order)
    |> maybe_eval_modifier(params, :offset)
    |> maybe_eval_modifier(params, :limit)
  end

  defp eval_modifier(collection, {:limit, limit}), do: collection |> Collection.limit(limit)
  defp eval_modifier(collection, {:offset, offset}), do: collection |> Collection.offset(offset)
  defp eval_modifier(collection, {:order, :reversed}), do: collection |> Collection.reverse()

  defp eval_for_offset(parameters, context, identifier) do
    eval_offset(
      parameters,
      context,
      identifier,
      &Context.for_loop_offset/2,
      &Context.for_loop_offset_reset/2
    )
  end

  defp eval_tablerow_offset(parameters, context, identifier) do
    eval_offset(
      parameters,
      context,
      identifier,
      &Context.tablerow_loop_offset/2,
      &Context.tablerow_loop_offset_reset/2
    )
  end

  defp maybe_reset(context, _identifier, :continue, _reset_fun), do: context
  defp maybe_reset(context, identifier, _offset, reset_fun), do: reset_fun.(context, identifier)

  defp eval_offset(parameters, context, identifier, offset_fun, reset_fun) do
    {
      Keyword.update(parameters, :offset, 0, fn
        :continue -> offset_fun.(context, identifier)
        offset -> offset
      end),
      maybe_reset(context, identifier, parameters[:offset], reset_fun)
    }
  end

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
            |> Context.for_loop_offset_inc(identifier)
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

        {[result | acc], Context.tablerow_loop_offset_inc(ctx, identifier)}
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
