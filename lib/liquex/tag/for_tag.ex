defmodule Liquex.Tag.ForTag do
  @behaviour Liquex.Tag
  import NimbleParsec

  alias Liquex.Collection
  alias Liquex.Context
  alias Liquex.Expression

  alias Liquex.Parser.Argument
  alias Liquex.Parser.Field
  alias Liquex.Parser.Literal
  alias Liquex.Parser.Tag

  def parse do
    for_in_tag()
    |> tag(parsec(:document), :contents)
    |> optional(else_tag())
    |> ignore(Tag.tag_directive("endfor"))
  end

  defp for_in_tag do
    collection = choice([Literal.range(), Argument.argument()])

    ignore(Tag.open_tag())
    |> ignore(string("for"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> unwrap_and_tag(Field.identifier(), :identifier)
    |> ignore(Literal.whitespace(empty(), 1))
    |> ignore(string("in"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> tag(collection, :collection)
    |> ignore(Literal.whitespace())
    |> tag(for_parameters(), :parameters)
    |> ignore(Tag.close_tag())
  end

  defp for_parameters do
    reversed =
      replace(string("reversed"), :reversed)
      |> unwrap_and_tag(:order)
      |> ignore(Literal.whitespace())

    limit =
      ignore(string("limit:"))
      |> unwrap_and_tag(integer(min: 1), :limit)
      |> ignore(Literal.whitespace())

    offset =
      ignore(string("offset:"))
      |> unwrap_and_tag(integer(min: 1), :offset)
      |> ignore(Literal.whitespace())

    repeat(
      choice([
        reversed,
        limit,
        offset
      ])
    )
  end

  defp else_tag do
    ignore(Tag.tag_directive("else"))
    |> tag(parsec(:document), :contents)
    |> tag(:else)
  end

  def render(
        [
          identifier: identifier,
          collection: collection,
          parameters: parameters,
          contents: contents,
          else: [contents: else_contents]
        ],
        %Context{} = context
      ) do
    collection
    |> Liquex.Argument.eval(context)
    |> Expression.eval_collection(parameters)
    |> Collection.to_enumerable()
    |> render_collection(identifier, contents, else_contents, context)
  end

  def render(content, %Context{} = context) do
    (content ++ [else: [contents: []]])
    |> render(context)
  end

  defp render_collection(nil, _, _, contents, context),
    do: Liquex.Render.render(contents, context)

  defp render_collection([], _, _, contents, context),
    do: Liquex.Render.render(contents, context)

  defp render_collection(results, identifier, contents, _, context) do
    forloop_init = Map.get(context.variables, "forloop")
    len = Enum.count(results)

    {result, context} =
      results
      |> Enum.with_index(0)
      |> Enum.reduce({[], context}, fn {record, index}, {acc, ctx} ->
        # Assign the loop variables
        ctx =
          ctx
          |> Context.assign("forloop", forloop(index, len))
          |> Context.assign(identifier, record)

        case Liquex.Render.render(contents, ctx) do
          {r, ctx} ->
            {[r | acc], Context.assign(ctx, "forloop", forloop_init)}

          {:continue, content, ctx} ->
            {content ++ acc, Context.assign(ctx, "forloop", forloop_init)}

          {:break, content, ctx} ->
            throw({:break, content ++ acc, Context.assign(ctx, "forloop", forloop_init)})
        end
      end)

    {Enum.reverse(result), context}
  catch
    {:break, result, context} ->
      # credo:disable-for-next-line
      {Enum.reverse(result), context}
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
