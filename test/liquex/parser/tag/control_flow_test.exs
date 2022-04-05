defmodule Liquex.Parser.Tag.ControlFlowTest do
  @moduledoc false

  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  describe "case_expression" do
    test "parse simple case statement" do
      "{% case a %} {% when 1 %}test{% endcase %}"
      |> assert_parse(
        control_flow: [
          {:case, [field: [key: "a"]]},
          {:when, [expression: [literal: 1], contents: [text: "test"]]}
        ]
      )
    end

    test "parse multiple case statement" do
      "{% case a %} {% when 1 %}test{% when 2 %}test2{% endcase %}"
      |> assert_parse(
        control_flow: [
          {:case, [field: [key: "a"]]},
          {:when, [expression: [literal: 1], contents: [text: "test"]]},
          {:when, [expression: [literal: 2], contents: [text: "test2"]]}
        ]
      )
    end

    test "parse case with else statement" do
      "{% case a %} {% when 1 %} test {% else %} test2 {% endcase %}"
      |> assert_parse(
        control_flow: [
          {:case, [field: [key: "a"]]},
          {:when, [expression: [literal: 1], contents: [text: " test "]]},
          {:else, contents: [text: " test2 "]}
        ]
      )
    end

    test "kitchen sink" do
      """
      {% case handle %}
        {% when "cake" %}
          This is a cake
        {% when "cookie" %}
          This is a cookie
        {% else %}
          This is not a cake nor a cookie
      {% endcase %}
      """
      |> assert_parse([
        {:control_flow,
         [
           case: [field: [key: "handle"]],
           when: [
             expression: [literal: "cake"],
             contents: [text: "\n    This is a cake\n  "]
           ],
           when: [
             expression: [literal: "cookie"],
             contents: [text: "\n    This is a cookie\n  "]
           ],
           else: [contents: [text: "\n    This is not a cake nor a cookie\n"]]
         ]},
        {:text, "\n"}
      ])
    end
  end
end
