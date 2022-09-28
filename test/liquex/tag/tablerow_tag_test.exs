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

      assert Liquex.render(template, context)
             |> elem(0)
             |> to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list()
             |> Enum.join() ==
               "<table><tr><td>1</td></tr><tr><td>2</td></tr><tr><td>3</td></tr></table>"

      assert render(
               """
                 <table>{% liquid tablerow product in collection
                   echo product
                 endtablerow %}</table>
               """,
               context
             ) == "<table><tr><td>1</td></tr><tr><td>2</td></tr><tr><td>3</td></tr></table>"
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

      assert Liquex.render(template, context)
             |> elem(0)
             |> to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list()
             |> Enum.join() ==
               "<table><tr><td>1</td><td>2</td></tr><tr><td>3</td><td></td></tr></table>"

      assert render(
               """
                 <table>{% liquid tablerow product in collection cols:2
                   echo product
                 endtablerow %}</table>
               """,
               context
             ) == "<table><tr><td>1</td><td>2</td></tr><tr><td>3</td><td></td></tr></table>"
    end
  end

  defp trim_list(list) do
    list
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end
end
