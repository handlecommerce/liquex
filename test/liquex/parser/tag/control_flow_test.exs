defmodule Liquex.Parser.Tag.ControlFlowTest do
  @moduledoc false

  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  describe "if_expression" do
    test "parse if block with boolean" do
      "{% if true %}Hello{% endif %}"
      |> assert_parse(
        control_flow: [if: [expression: [literal: true], contents: [text: "Hello"]]]
      )
    end

    test "parse if block with conditional" do
      "{% if a == b %}Hello{% endif %}"
      |> assert_parse(
        control_flow: [
          if: [
            expression: [[left: [field: [key: "a"]], op: :==, right: [field: [key: "b"]]]],
            contents: [text: "Hello"]
          ]
        ]
      )
    end

    test "parse if block with and" do
      "{% if true and false %}Hello{% endif %}"
      |> assert_parse(
        control_flow: [
          if: [
            expression: [{:literal, true}, :and, {:literal, false}],
            contents: [text: "Hello"]
          ]
        ]
      )

      "{% if true or false %}Hello{% endif %}"
      |> assert_parse(
        control_flow: [
          if: [
            expression: [{:literal, true}, :or, {:literal, false}],
            contents: [text: "Hello"]
          ]
        ]
      )

      "{% if a > b and b > c %}Hello{% endif %}"
      |> assert_parse(
        control_flow: [
          if: [
            expression: [
              [left: [field: [key: "a"]], op: :>, right: [field: [key: "b"]]],
              :and,
              [left: [field: [key: "b"]], op: :>, right: [field: [key: "c"]]]
            ],
            contents: [text: "Hello"]
          ]
        ]
      )

      "{% if a and b > c %}Hello{% endif %}"
      |> assert_parse(
        control_flow: [
          if: [
            expression: [
              {:field, [key: "a"]},
              :and,
              [left: [field: [key: "b"]], op: :>, right: [field: [key: "c"]]]
            ],
            contents: [text: "Hello"]
          ]
        ]
      )
    end

    test "parse if block with elsif" do
      "{% if true %}Hello{% elsif false %}Goodbye{% endif %}"
      |> assert_parse(
        control_flow: [
          if: [
            expression: [literal: true],
            contents: [text: "Hello"]
          ],
          elsif: [
            expression: [literal: false],
            contents: [text: "Goodbye"]
          ]
        ]
      )

      "{% if true %}Hello{% elsif false %}Goodbye{% elsif 1 %}Other{% endif %}"
      |> assert_parse(
        control_flow: [
          if: [
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

    test "parse if block with else" do
      "{% if true %}Hello{% else %}Goodbye{% endif %}"
      |> assert_parse(
        control_flow: [
          if: [
            expression: [literal: true],
            contents: [text: "Hello"]
          ],
          else: [
            contents: [text: "Goodbye"]
          ]
        ]
      )
    end

    test "parse if block with ifelse and else" do
      "{% if true %}one{% elsif false %}two{% else %}three{% endif %}"
      |> assert_parse(
        control_flow: [
          if: [
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

    test "kitchen sink" do
      """
        {% if customer.name == "kevin" %}
          Hey Kevin!
        {% elsif customer.name == "anonymous" %}
          Hey Anonymous!
        {% else %}
          Hi Stranger!
        {% endif %}
      """
      |> assert_parse([
        {:text, "  "},
        {:control_flow,
         [
           if: [
             expression: [
               [left: [field: [key: "customer", key: "name"]], op: :==, right: [literal: "kevin"]]
             ],
             contents: [text: "\n    Hey Kevin!\n  "]
           ],
           elsif: [
             expression: [
               [
                 left: [field: [key: "customer", key: "name"]],
                 op: :==,
                 right: [literal: "anonymous"]
               ]
             ],
             contents: [text: "\n    Hey Anonymous!\n  "]
           ],
           else: [contents: [text: "\n    Hi Stranger!\n  "]]
         ]},
        {:text, "\n"}
      ])
    end
  end

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
