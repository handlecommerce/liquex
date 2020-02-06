defmodule Liquex.Parser.ConditionalBlockTest do
  use ExUnit.Case

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
        if: [
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
        if: [
          expression: [literal: false],
          contents: [text: ["Goodbye"]]
        ],
        if: [
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
        if: [
          expression: [literal: false],
          contents: [text: ["two"]]
        ],
        else: [
          contents: [text: ["three"]]
        ]
      ]
    )
  end

  def assert_parse(doc, match) do
    assert {:ok, ^match, "", _, _, _} = Liquex.Parser.parse(doc)
  end
end
