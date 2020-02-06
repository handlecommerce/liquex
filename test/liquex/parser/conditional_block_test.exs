defmodule Liquex.Parser.ConditionalBlockTest do
  use ExUnit.Case

  describe "if_tag" do
    test "parse if block with boolean" do
      "{% if true %}Hello{% endif %}"
      |> assert_parse(tag: [if: [expression: [literal: true], contents: [text: ["Hello"]]]])
    end

    test "parse if block with conditional" do
      "{% if a == b %}Hello{% endif %}"
      |> assert_parse(
        tag: [
          if: [
            expression: [[left: [field: [key: "a"]], op: :==, right: [field: [key: "b"]]]],
            contents: [text: ["Hello"]]
          ]
        ]
      )
    end

    test "parse if block with and" do
      "{% if true and false %}Hello{% endif %}"
      |> assert_parse(
        tag: [
          if: [
            expression: [{:literal, true}, :and, {:literal, false}],
            contents: [text: ["Hello"]]
          ]
        ]
      )

      "{% if true or false %}Hello{% endif %}"
      |> assert_parse(
        tag: [
          if: [
            expression: [{:literal, true}, :or, {:literal, false}],
            contents: [text: ["Hello"]]
          ]
        ]
      )

      "{% if a > b and b > c %}Hello{% endif %}"
      |> assert_parse(
        tag: [
          if: [
            expression: [
              [left: [field: [key: "a"]], op: :>, right: [field: [key: "b"]]],
              :and,
              [left: [field: [key: "b"]], op: :>, right: [field: [key: "c"]]]
            ],
            contents: [text: ["Hello"]]
          ]
        ]
      )
    end

    test "parse if block with elsif" do
      "{% if true %}Hello{% elsif false %}Goodbye{% endif %}"
      |> assert_parse(
        tag: [
          if: [
            expression: [literal: true],
            contents: [text: ["Hello"]]
          ],
          elsif: [
            expression: [literal: false],
            contents: [text: ["Goodbye"]]
          ]
        ]
      )

      "{% if true %}Hello{% elsif false %}Goodbye{% elsif 1 %}Other{% endif %}"
      |> assert_parse(
        tag: [
          if: [
            expression: [literal: true],
            contents: [text: ["Hello"]]
          ],
          elsif: [
            expression: [literal: false],
            contents: [text: ["Goodbye"]]
          ],
          elsif: [
            expression: [literal: 1],
            contents: [text: ["Other"]]
          ]
        ]
      )
    end

    test "parse if block with else" do
      "{% if true %}Hello{% else %}Goodbye{% endif %}"
      |> assert_parse(
        tag: [
          if: [
            expression: [literal: true],
            contents: [text: ["Hello"]]
          ],
          else: [
            contents: [text: ["Goodbye"]]
          ]
        ]
      )
    end

    test "parse if block with ifelse and else" do
      "{% if true %}one{% elsif false %}two{% else %}three{% endif %}"
      |> assert_parse(
        tag: [
          if: [
            expression: [literal: true],
            contents: [text: ["one"]]
          ],
          elsif: [
            expression: [literal: false],
            contents: [text: ["two"]]
          ],
          else: [
            contents: [text: ["three"]]
          ]
        ]
      )
    end
  end

  describe "unless_tag" do
    test "parse unless block with boolean" do
      "{% unless true %}Hello{% endunless %}"
      |> assert_parse(tag: [unless: [expression: [literal: true], contents: [text: ["Hello"]]]])
    end

    test "parse unless block with conditional" do
      "{% unless a == b %}Hello{% endunless %}"
      |> assert_parse(
        tag: [
          unless: [
            expression: [[left: [field: [key: "a"]], op: :==, right: [field: [key: "b"]]]],
            contents: [text: ["Hello"]]
          ]
        ]
      )
    end

    test "parse unless block with and" do
      "{% unless true and false %}Hello{% endunless %}"
      |> assert_parse(
        tag: [
          unless: [
            expression: [{:literal, true}, :and, {:literal, false}],
            contents: [text: ["Hello"]]
          ]
        ]
      )

      "{% unless true or false %}Hello{% endunless %}"
      |> assert_parse(
        tag: [
          unless: [
            expression: [{:literal, true}, :or, {:literal, false}],
            contents: [text: ["Hello"]]
          ]
        ]
      )

      "{% unless a > b and b > c %}Hello{% endunless %}"
      |> assert_parse(
        tag: [
          unless: [
            expression: [
              [left: [field: [key: "a"]], op: :>, right: [field: [key: "b"]]],
              :and,
              [left: [field: [key: "b"]], op: :>, right: [field: [key: "c"]]]
            ],
            contents: [text: ["Hello"]]
          ]
        ]
      )
    end

    test "parse unless block with elsif" do
      "{% unless true %}Hello{% elsif false %}Goodbye{% endunless %}"
      |> assert_parse(
        tag: [
          unless: [
            expression: [literal: true],
            contents: [text: ["Hello"]]
          ],
          elsif: [
            expression: [literal: false],
            contents: [text: ["Goodbye"]]
          ]
        ]
      )

      "{% unless true %}Hello{% elsif false %}Goodbye{% elsif 1 %}Other{% endunless %}"
      |> assert_parse(
        tag: [
          unless: [
            expression: [literal: true],
            contents: [text: ["Hello"]]
          ],
          elsif: [
            expression: [literal: false],
            contents: [text: ["Goodbye"]]
          ],
          elsif: [
            expression: [literal: 1],
            contents: [text: ["Other"]]
          ]
        ]
      )
    end

    test "parse unless block with else" do
      "{% unless true %}Hello{% else %}Goodbye{% endunless %}"
      |> assert_parse(
        tag: [
          unless: [
            expression: [literal: true],
            contents: [text: ["Hello"]]
          ],
          else: [
            contents: [text: ["Goodbye"]]
          ]
        ]
      )
    end

    test "parse unless block with ifelse and else" do
      "{% unless true %}one{% elsif false %}two{% else %}three{% endunless %}"
      |> assert_parse(
        tag: [
          unless: [
            expression: [literal: true],
            contents: [text: ["one"]]
          ],
          elsif: [
            expression: [literal: false],
            contents: [text: ["two"]]
          ],
          else: [
            contents: [text: ["three"]]
          ]
        ]
      )
    end
  end

  def assert_parse(doc, match) do
    assert {:ok, ^match, "", _, _, _} = Liquex.Parser.parse(doc)
  end
end
