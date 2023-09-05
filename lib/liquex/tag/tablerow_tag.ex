defmodule Liquex.Tag.TablerowTag do
  @moduledoc """
  Generates an HTML table. Must be wrapped in opening <table> and closing
  </table> HTML tags. For a full list of attributes available within a tablerow
  loop, see tablerow (object).

  ### Input

      <table>
      {% tablerow product in collection.products %}
        {{ product.title }}
      {% endtablerow %}
      </table>

  ### Output

      <table>
        <tr class="row1">
          <td class="col1">
            Cool Shirt
          </td>
          <td class="col2">
            Alien Poster
          </td>
          <td class="col3">
            Batman Poster
          </td>
          <td class="col4">
            Bullseye Shirt
          </td>
          <td class="col5">
            Another Classic Vinyl
          </td>
          <td class="col6">
            Awesome Jeans
          </td>
        </tr>
      </table>

  # tablerow (parameters)

  ## cols

  Defines how many columns the tables should have.

  ### Input

      {% tablerow product in collection.products cols:2 %}
        {{ product.title }}
      {% endtablerow %}

  ### Output

      <table>
        <tr class="row1">
          <td class="col1">
            Cool Shirt
          </td>
          <td class="col2">
            Alien Poster
          </td>
        </tr>
        <tr class="row2">
          <td class="col1">
            Batman Poster
          </td>
          <td class="col2">
            Bullseye Shirt
          </td>
        </tr>
        <tr class="row3">
          <td class="col1">
            Another Classic Vinyl
          </td>
          <td class="col2">
            Awesome Jeans
          </td>
        </tr>
      </table>

  ## limit

  Exits the tablerow loop after a specific index.

      {% tablerow product in collection.products cols:2 limit:3 %}
        {{ product.title }}
      {% endtablerow %}

  ## offset

  Starts the tablerow loop after a specific index.

      {% tablerow product in collection.products cols:2 offset:3 %}
        {{ product.title }}
      {% endtablerow %}

  ## range

  Defines a range of numbers to loop through. The range can be defined by both
  literal and variable numbers.

      <!--variable number example-->

      {% assign num = 4 %}
      <table>
      {% tablerow i in (1..num) %}
        {{ i }}
      {% endtablerow %}
      </table>

      <!--literal number example-->

      <table>
      {% tablerow i in (3..5) %}
        {{ i }}
      {% endtablerow %}
      </table>
  """

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
    ignore(Tag.open_tag())
    |> do_parse_tablerow()
    |> ignore(Tag.close_tag())
    |> tag(parsec(:document), :contents)
    |> ignore(Tag.tag_directive("endtablerow"))
  end

  def parse_liquid_tag do
    do_parse_tablerow()
    |> ignore(Tag.end_liquid_line())
    |> tag(parsec(:liquid_tag_contents), :contents)
    |> ignore(Tag.liquid_tag_directive("endtablerow"))
  end

  defp do_parse_tablerow(combinator \\ empty()) do
    collection = choice([Literal.range(), Argument.argument()])

    cols =
      ignore(string("cols:"))
      |> unwrap_and_tag(integer(min: 1), :cols)
      |> ignore(Literal.non_breaking_whitespace())

    limit =
      ignore(string("limit:"))
      |> unwrap_and_tag(integer(min: 1), :limit)
      |> ignore(Literal.non_breaking_whitespace())

    offset =
      ignore(string("offset:"))
      |> unwrap_and_tag(integer(min: 1), :offset)
      |> ignore(Literal.non_breaking_whitespace())

    tablerow_parameters = repeat(choice([cols, limit, offset]))

    combinator
    |> ignore(string("tablerow"))
    |> ignore(Literal.non_breaking_whitespace(empty(), 1))
    |> unwrap_and_tag(Field.identifier(), :identifier)
    |> ignore(Literal.non_breaking_whitespace(empty(), 1))
    |> ignore(string("in"))
    |> ignore(Literal.non_breaking_whitespace(empty(), 1))
    |> tag(collection, :collection)
    |> ignore(Literal.non_breaking_whitespace())
    |> tag(tablerow_parameters, :parameters)
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

    {value, context} =
      collection
      |> Liquex.Argument.eval(context)

    value
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

        {result, ctx} = Render.render!(contents, ctx)

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
