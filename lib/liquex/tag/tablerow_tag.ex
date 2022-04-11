defmodule Liquex.Tag.TablerowTag do
  @moduledoc false

  @behaviour Liquex.Tag

  alias Liquex.Context
  alias Liquex.Render

  alias Liquex.Parser.Argument
  alias Liquex.Parser.Field
  alias Liquex.Parser.Literal
  alias Liquex.Parser.Tag

  alias Liquex.Expression
  import NimbleParsec

  def parse do
    collection = choice([Literal.range(), Argument.argument()])

    cols =
      ignore(string("cols:"))
      |> unwrap_and_tag(integer(min: 1), :cols)
      |> ignore(Literal.whitespace())

    limit =
      ignore(string("limit:"))
      |> unwrap_and_tag(integer(min: 1), :limit)
      |> ignore(Literal.whitespace())

    offset =
      ignore(string("offset:"))
      |> unwrap_and_tag(integer(min: 1), :offset)
      |> ignore(Literal.whitespace())

    tablerow_parameters = repeat(choice([cols, limit, offset]))

    ignore(Tag.open_tag())
    |> ignore(string("tablerow"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> unwrap_and_tag(Field.identifier(), :identifier)
    |> ignore(Literal.whitespace(empty(), 1))
    |> ignore(string("in"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> tag(collection, :collection)
    |> ignore(Literal.whitespace())
    |> tag(tablerow_parameters, :parameters)
    |> ignore(Tag.close_tag())
    |> tag(parsec(:document), :contents)
    |> ignore(Tag.tag_directive("endtablerow"))
  end

  def render(
        [
          identifier: identifier,
          collection: collection,
          parameters: parameters,
          contents: contents
        ],
        context
      ) do
    cols = Keyword.get(parameters, :cols, 1)

    collection
    |> Liquex.Argument.eval(context)
    |> Expression.eval_collection(parameters)
    |> Liquex.Collection.to_enumerable()
    |> render_row(identifier, contents, cols, context)
  end

  defp render_row(collection, identifier, contents, cols, context) do
    {results, context} =
      collection
      |> Enum.with_index()
      |> Enum.reduce({[], context}, fn {record, idx}, {acc, ctx} ->
        ctx = Context.assign(ctx, identifier, record)

        {result, ctx} = Render.render(contents, ctx)

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
end
