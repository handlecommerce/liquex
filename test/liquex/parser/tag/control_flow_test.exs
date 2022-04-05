defmodule Liquex.Parser.Tag.ControlFlowTest do
  @moduledoc false

  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  describe "unless_expression" do
    test "parse unless block with boolean" do
      "{% unless true %}Hello{% endunless %}"
      |> assert_parse(
        control_flow: [unless: [expression: [literal: true], contents: [text: "Hello"]]]
      )
    end

    test "parse unless block with conditional" do
      "{% unless a == b %}Hello{% endunless %}"
      |> assert_parse(
        control_flow: [
          unless: [
            expression: [[left: [field: [key: "a"]], op: :==, right: [field: [key: "b"]]]],
            contents: [text: "Hello"]
          ]
        ]
      )
    end

    test "parse unless block with and" do
      "{% unless true and false %}Hello{% endunless %}"
      |> assert_parse(
        control_flow: [
          unless: [
            expression: [{:literal, true}, :and, {:literal, false}],
            contents: [text: "Hello"]
          ]
        ]
      )

      "{% unless true or false %}Hello{% endunless %}"
      |> assert_parse(
        control_flow: [
          unless: [
            expression: [{:literal, true}, :or, {:literal, false}],
            contents: [text: "Hello"]
          ]
        ]
      )

      "{% unless a > b and b > c %}Hello{% endunless %}"
      |> assert_parse(
        control_flow: [
          unless: [
            expression: [
              [left: [field: [key: "a"]], op: :>, right: [field: [key: "b"]]],
              :and,
              [left: [field: [key: "b"]], op: :>, right: [field: [key: "c"]]]
            ],
            contents: [text: "Hello"]
          ]
        ]
      )
    end

    test "parse unless block with elsif" do
      "{% unless true %}Hello{% elsif false %}Goodbye{% endunless %}"
      |> assert_parse(
        control_flow: [
          unless: [
            expression: [literal: true],
            contents: [text: "Hello"]
          ],
          elsif: [
            expression: [literal: false],
            contents: [text: "Goodbye"]
          ]
        ]
      )

      "{% unless true %}Hello{% elsif false %}Goodbye{% elsif 1 %}Other{% endunless %}"
      |> assert_parse(
        control_flow: [
          unless: [
            expression: [literal: true],
            contents: [text: "Hello"]
          ],
          elsif: [
            expression: [literal: false],
            contents: [text: "Goodbye"]
          ],
          elsif: [
            expression: [literal: 1],
            contents: [text: "Other"]
          ]
        ]
      )
    end

    test "parse unless block with else" do
      "{% unless true %}Hello{% else %}Goodbye{% endunless %}"
      |> assert_parse(
        control_flow: [
          unless: [
            expression: [literal: true],
            contents: [text: "Hello"]
          ],
          else: [
            contents: [text: "Goodbye"]
          ]
        ]
      )
    end

    test "parse unless block with ifelse and else" do
      "{% unless true %}one{% elsif false %}two{% else %}three{% endunless %}"
      |> assert_parse(
        control_flow: [
          unless: [
            expression: [literal: true],
            contents: [text: "one"]
          ],
          elsif: [
            expression: [literal: false],
            contents: [text: "two"]
          ],
          else: [
            contents: [text: "three"]
          ]
        ]
      )
    end
  end

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
