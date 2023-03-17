defmodule Liquex.Tag.TablerowTagTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  alias Liquex.Context

  describe "parse" do
    test "parse simple tablerow" do
      "{% tablerow product in collection %}{{ product }}{% endtablerow %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.TablerowTag},
          identifier: "product",
          collection: [field: [key: "collection"]],
          parameters: [],
          contents: [{{:tag, Liquex.Tag.ObjectTag}, [field: [key: "product"], filters: []]}]
        }
      ])
    end

    test "parse tablerow with parameters" do
      "{% tablerow product in collection cols:2 limit:3 offset:2 %}{{ product }}{% endtablerow %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.TablerowTag},
          identifier: "product",
          collection: [field: [key: "collection"]],
          parameters: [cols: 2, limit: 3, offset: 2],
          contents: [{{:tag, Liquex.Tag.ObjectTag}, [field: [key: "product"], filters: []]}]
        }
      ])
    end
  end

  describe "render" do
    test "simple tablerow" do
      {:ok, template} =
        """
        <table>
        {% tablerow product in collection %}
          {{ product }}
        {% endtablerow %}
        </table>
        """
        |> String.trim()
        |> Liquex.parse()

      context = Context.new(%{"collection" => [1, 2, 3]})

      assert Liquex.render!(template, context)
             |> elem(0)
             |> to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list()
             |> Enum.join() ==
               ~s(<table><tr class="row1"><td class="col1">1</td><td class="col2">2</td><td class="col3">3</td></tr></table>)

      assert render(
               """
                 <table>{% liquid tablerow product in collection
                   echo product
                 endtablerow %}</table>
               """,
               context
             ) ==
               ~s(<table><tr class="row1">\n<td class="col1">1</td><td class="col2">2</td><td class="col3">3</td></tr>\n</table>)
    end

    test "tablerow with cols" do
      {:ok, template} =
        """
        <table>
        {% tablerow product in collection cols:2 %}
          {{ product }}
        {% endtablerow %}
        </table>
        """
        |> String.trim()
        |> Liquex.parse()

      context = Context.new(%{"collection" => [1, 2, 3]})

      assert Liquex.render!(template, context)
             |> elem(0)
             |> to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list()
             |> Enum.join() ==
               ~s(<table><tr class="row1"><td class="col1">1</td><td class="col2">2</td></tr><tr class="row2"><td class="col1">3</td></tr></table>)

      assert render(
               """
                 <table>{% liquid tablerow product in collection cols:2
                   echo product
                 endtablerow %}</table>
               """,
               context
             ) ==
               ~s(<table><tr class="row1">\n<td class="col1">1</td><td class="col2">2</td></tr>\n<tr class="row2"><td class="col1">3</td></tr>\n</table>)
    end

    test "tablerowloop drop" do
      {:ok, template} =
        """
        {% tablerow product in collection cols:2 %}
          {{ tablerowloop.col }}
          {{ tablerowloop.col0 }}
          {{ tablerowloop.col_first }}
          {{ tablerowloop.col_last }}
          {{ tablerowloop.first }}
          {{ tablerowloop.index }}
          {{ tablerowloop.index0 }}
          {{ tablerowloop.last }}
          {{ tablerowloop.length }}
          {{ tablerowloop.rindex }}
          {{ tablerowloop.rindex0 }}
          {{ tablerowloop.row }}
        {% endtablerow %}
        """
        |> String.trim()
        |> Liquex.parse()

      context = Context.new(%{"collection" => [1, 2, 3]})

      assert Liquex.render!(template, context)
             |> elem(0)
             |> to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list()
             |> Enum.join() ==
               ~s(<tr class="row1"><td class="col1">10truefalsetrue10false3321</td><td class="col2">21falsetruefalse21false3211</td></tr><tr class="row2"><td class="col1">10truefalsefalse32true3102</td></tr>)
    end
  end

  defp trim_list(list) do
    list
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end
end
