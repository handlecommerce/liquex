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
    test "default cols puts every item in a single row with column classes" do
      context = Context.new(%{"collection" => [1, 2, 3]})

      assert render_template("<table>{% tablerow p in collection %}{{ p }}{% endtablerow %}</table>", context) ==
               ~s(<table><tr class="row1">\n<td class="col1">1</td><td class="col2">2</td><td class="col3">3</td></tr>\n</table>)

      assert render_template(
               "<table>{% liquid tablerow p in collection\necho p\nendtablerow %}</table>",
               context
             ) ==
               ~s(<table><tr class="row1">\n<td class="col1">1</td><td class="col2">2</td><td class="col3">3</td></tr>\n</table>)
    end

    test "cols wraps and emits row classes without padding empty cells" do
      context = Context.new(%{"collection" => [1, 2, 3, 4, 5]})

      assert render_template(
               "<table>{% tablerow p in collection cols:2 %}{{ p }}{% endtablerow %}</table>",
               context
             ) ==
               ~s(<table><tr class="row1">\n) <>
                 ~s(<td class="col1">1</td><td class="col2">2</td>) <>
                 ~s(</tr>\n<tr class="row2">) <>
                 ~s(<td class="col1">3</td><td class="col2">4</td>) <>
                 ~s(</tr>\n<tr class="row3">) <>
                 ~s(<td class="col1">5</td>) <>
                 ~s(</tr>\n</table>)
    end

    test "exposes tablerowloop fields" do
      context = Context.new(%{"collection" => [10, 20, 30]})

      out =
        render_template(
          "{% tablerow p in collection cols:2 %}" <>
            "{{ tablerowloop.index }}-{{ tablerowloop.col }}-{{ tablerowloop.row }}-" <>
            "{{ tablerowloop.col_first }}-{{ tablerowloop.col_last }}-" <>
            "{{ tablerowloop.first }}-{{ tablerowloop.last }}|" <>
            "{% endtablerow %}",
          context
        )

      assert out ==
               ~s(<tr class="row1">\n) <>
                 ~s(<td class="col1">1-1-1-true-false-true-false|</td>) <>
                 ~s(<td class="col2">2-2-1-false-true-false-false|</td>) <>
                 ~s(</tr>\n<tr class="row2">) <>
                 ~s(<td class="col1">3-1-2-true-false-false-true|</td>) <>
                 ~s(</tr>\n)
    end

    test "empty collection still emits an empty row" do
      context = Context.new(%{"collection" => []})

      assert render_template("{% tablerow p in collection %}{{ p }}{% endtablerow %}", context) ==
               ~s(<tr class="row1">\n</tr>\n)
    end

    test "nil collection renders nothing" do
      context = Context.new(%{"collection" => nil})

      assert render_template("{% tablerow p in collection %}{{ p }}{% endtablerow %}", context) ==
               ""
    end
  end

  defp render_template(template, context) do
    {:ok, parsed} = Liquex.parse(template)
    parsed |> Liquex.render!(context) |> elem(0) |> to_string()
  end
end
