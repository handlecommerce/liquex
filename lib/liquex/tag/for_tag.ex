defmodule Liquex.Tag.ForTag do
  @moduledoc """
  Repeatedly executes a block of code. For a full list of attributes available
  within a for loop, see forloop (object).

  ### Input
      {% for product in collection.products %}
        {{ product.title }}
      {% endfor %}

  ### Output

      hat shirt pants

  ## else

  Specifies a fallback case for a for loop which will run if the loop has zero length.

  ### Input

      {% for product in collection.products %}
        {{ product.title }}
      {% else %}
        The collection is empty.
      {% endfor %}

  ### Output

  The collection is empty.

  ## break

  Causes the loop to stop iterating when it encounters the break tag.

  ### Input

      {% for i in (1..5) %}
        {% if i == 4 %}
          {% break %}
        {% else %}
          {{ i }}
        {% endif %}
      {% endfor %}

  ### Output

      1 2 3

  ## continue

  Causes the loop to skip the current iteration when it encounters the continue
  tag.

  ### Input

      {% for i in (1..5) %}
        {% if i == 4 %}
          {% continue %}
        {% else %}
          {{ i }}
        {% endif %}
      {% endfor %}

  ### Output

      1 2 3   5

  # for (parameters)

  ## limit

  Limits the loop to the specified number of iterations.

  ### Input

      <!-- if array = [1,2,3,4,5,6] -->
      {% for item in array limit:2 %}
        {{ item }}
      {% endfor %}

  ### Output

      1 2

  ## offset

  Begins the loop at the specified index.

  ### Input

      <!-- if array = [1,2,3,4,5,6] -->
      {% for item in array offset:2 %}
        {{ item }}
      {% endfor %}

  ### Output

      3 4 5 6

  To start a loop from where the last loop using the same iterator left off,
  pass the special word continue.

  ### Input

      <!-- if array = [1,2,3,4,5,6] -->
      {% for item in array limit: 3 %}
        {{ item }}
      {% endfor %}
      {% for item in array limit: 3 offset: continue %}
        {{ item }}
      {% endfor %}

  ### Output

      1 2 3
      4 5 6

  ## range

  Defines a range of numbers to loop through. The range can be defined by both
  literal and variable numbers, and can be pulled from a variable.

  ### Input

      {% for i in (3..5) %}
        {{ i }}
      {% endfor %}

      {% assign num = 4 %}
      {% assign range = (1..num) %}
      {% for i in range %}
        {{ i }}
      {% endfor %}

  ### Output

      3 4 5
      1 2 3 4

  ## reversed

  Reverses the order of the loop. Note that this flag’s spelling is different
  from the filter reverse.

  ### Input

      <!-- if array = [1,2,3,4,5,6] -->
      {% for item in array reversed %}
        {{ item }}
      {% endfor %}

  ### Output

      6 5 4 3 2 1
  """

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

  def render_collection(nil, _, _, contents, context),
    do: Liquex.Render.render(contents, context)

  def render_collection([], _, _, contents, context),
    do: Liquex.Render.render(contents, context)

  def render_collection(results, identifier, contents, _, context) do
    len = Enum.count(results)

    {result, context} =
      results
      |> Enum.with_index(0)
      |> Enum.reduce({[], context}, fn {record, index}, {acc, ctx} ->
        # Assign the loop variables
        ctx =
          Context.push_scope(ctx, %{
            "forloop" => forloop(index, len),
            identifier => record
          })

        case Liquex.Render.render(contents, ctx) do
          {r, ctx} ->
            {[r | acc], Context.pop_scope(ctx)}

          {:continue, content, ctx} ->
            {content ++ acc, Context.pop_scope(ctx)}

          {:break, content, ctx} ->
            throw({:break, content ++ acc, Context.pop_scope(ctx)})
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
