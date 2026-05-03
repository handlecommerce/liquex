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
      |> ignore(Literal.non_breaking_whitespace())
      |> unwrap_and_tag(Argument.argument(), :cols)

    limit =
      ignore(string("limit:"))
      |> ignore(Literal.non_breaking_whitespace())
      |> unwrap_and_tag(Argument.argument(), :limit)

    offset =
      ignore(string("offset:"))
      |> ignore(Literal.non_breaking_whitespace())
      |> unwrap_and_tag(Argument.argument(), :offset)

    parameter = choice([cols, limit, offset])

    parameters =
      optional(
        parameter
        |> repeat(
          ignore(Literal.non_breaking_whitespace())
          |> optional(ignore(string(",")))
          |> ignore(Literal.non_breaking_whitespace())
          |> concat(parameter)
        )
      )

    combinator
    |> ignore(string("tablerow"))
    |> ignore(Literal.non_breaking_whitespace(empty(), 1))
    |> unwrap_and_tag(Field.identifier(), :identifier)
    |> ignore(Literal.non_breaking_whitespace(empty(), 1))
    |> ignore(string("in"))
    |> ignore(Literal.non_breaking_whitespace(empty(), 1))
    |> tag(collection, :collection)
    |> ignore(Literal.non_breaking_whitespace())
    |> tag(parameters, :parameters)
    |> ignore(Literal.non_breaking_whitespace())
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
    parameters = evaluate_params(parameters, context)
    cols = Keyword.get(parameters, :cols)

    case collection
         |> Liquex.Argument.eval(context)
         |> Expression.eval_collection(parameters) do
      nil ->
        {[], context}

      evaluated ->
        evaluated
        |> Liquex.Collection.to_enumerable()
        |> render_row(identifier, contents, cols, context)
    end
  end

  # Resolves parameter ASTs (which can be literal integers, variables, or
  # strings like "3") into integers, the way Liquid coerces them.
  defp evaluate_params(parameters, context) do
    Enum.map(parameters, fn {key, ast} ->
      {key, ast |> Liquex.Argument.eval(context) |> to_integer()}
    end)
  end

  defp to_integer(n) when is_integer(n), do: n
  defp to_integer(n) when is_float(n), do: trunc(n)

  defp to_integer(s) when is_binary(s) do
    case Integer.parse(s) do
      {n, _} -> n
      :error -> 0
    end
  end

  defp to_integer(_), do: 0

  defp render_row(collection, identifier, contents, cols, context) do
    items = Enum.to_list(collection)
    length = length(items)
    cols = cols || max(length, 1)

    {results, context} =
      items
      |> Enum.with_index()
      |> Enum.reduce({[], context}, fn {record, idx}, {acc, ctx} ->
        loop = tablerowloop(idx, length, cols)

        ctx =
          Context.push_scope(ctx, %{
            "tablerowloop" => loop,
            identifier => record
          })

        {rendered, ctx} = Render.render!(contents, ctx)
        ctx = Context.pop_scope(ctx)

        cell = [
          ~s(<td class="col),
          Integer.to_string(loop["col"]),
          ~s(">),
          rendered,
          "</td>"
        ]

        separator =
          if loop["col_last"] and not loop["last"] do
            [~s(</tr>\n<tr class="row), Integer.to_string(loop["row"] + 1), ~s(">)]
          else
            []
          end

        {[separator, cell | acc], ctx}
      end)

    output = [~s(<tr class="row1">\n), Enum.reverse(results), "</tr>\n"]
    {output, context}
  end

  defp tablerowloop(idx, length, cols) do
    col = rem(idx, cols) + 1

    %{
      "length" => length,
      "index" => idx + 1,
      "index0" => idx,
      "rindex" => length - idx,
      "rindex0" => length - idx - 1,
      "col" => col,
      "col0" => col - 1,
      "row" => div(idx, cols) + 1,
      "first" => idx == 0,
      "last" => idx == length - 1,
      "col_first" => col == 1,
      "col_last" => col == cols
    }
  end
end
