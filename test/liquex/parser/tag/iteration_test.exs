defmodule Liquex.Parser.Tag.IterationTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  describe "for_expression" do
    test "parse for block with field" do
      "{% for i in x %}Hello{% endfor %}"
      |> assert_parse(
        iteration: [
          for: [
            {:identifier, ["i"]},
            {:collection, [field: [key: "x"]]},
            {:contents, [text: "Hello"]}
          ]
        ]
      )
    end

    test "parse for block with else" do
      "{% for i in x %}Hello{% else %}Goodbye{% endfor %}"
      |> assert_parse(
        iteration: [
          for: [
            {:identifier, ["i"]},
            {:collection, [field: [key: "x"]]},
            {:contents, [text: "Hello"]}
          ],
          else: [contents: [text: "Goodbye"]]
        ]
      )
    end

    test "parse for block with range" do
      "{% for i in (1..5) %}Hello{% endfor %}"
      |> assert_parse(
        iteration: [
          for: [
            identifier: ["i"],
            collection: [inclusive_range: [{:begin, [literal: 1]}, {:end, [literal: 5]}]],
            contents: [text: "Hello"]
          ]
        ]
      )
    end

    test "parse for block with variable range" do
      "{% for i in (1..x) %}Hello{% endfor %}"
      |> assert_parse(
        iteration: [
          for: [
            identifier: ["i"],
            collection: [inclusive_range: [{:begin, [literal: 1]}, {:end, [field: [key: "x"]]}]],
            contents: [text: "Hello"]
          ]
        ]
      )
    end

    test "parse for block with reversed" do
      "{% for i in x reversed %}Hello{% endfor %}"
      |> assert_parse(
        iteration: [
          for: [
            {:identifier, ["i"]},
            {:collection, [field: [key: "x"], order: :reversed]},
            {:contents, [text: "Hello"]}
          ]
        ]
      )
    end

    test "parse for block with limit" do
      "{% for i in x limit:2 %}Hello{% endfor %}"
      |> assert_parse(
        iteration: [
          for: [
            {:identifier, ["i"]},
            {:collection, [field: [key: "x"], limit: 2]},
            {:contents, [text: "Hello"]}
          ]
        ]
      )
    end

    test "parse for block with offset" do
      "{% for i in x offset:1 %}Hello{% endfor %}"
      |> assert_parse(
        iteration: [
          for: [
            {:identifier, ["i"]},
            {:collection, [field: [key: "x"], offset: 1]},
            {:contents, [text: "Hello"]}
          ]
        ]
      )
    end

    test "parse for block with reverse, limit, and offset" do
      "{% for i in x reversed limit:2 offset:1 %}Hello{% endfor %}"
      |> assert_parse(
        iteration: [
          for: [
            {:identifier, ["i"]},
            {:collection, [field: [key: "x"], order: :reversed, limit: 2, offset: 1]},
            {:contents, [text: "Hello"]}
          ]
        ]
      )
    end
  end

  describe "cycle_tag" do
    test "parse cycle block with string sequence" do
      "{% cycle 'a', 'b', 'c' %}"
      |> assert_parse(
        iteration: [cycle: [sequence: [{:literal, "a"}, {:literal, "b"}, {:literal, "c"}]]]
      )
    end

    test "parse cycle block with arguments" do
      "{% cycle a, b, c %}"
      |> assert_parse(
        iteration: [cycle: [sequence: [field: [key: "a"], field: [key: "b"], field: [key: "c"]]]]
      )
    end

    test "parse cycle block with cycle group" do
      "{% cycle 'group': 'a', 'b', 'c' %}"
      |> assert_parse(
        iteration: [
          cycle: [
            {:group, {:literal, "group"}},
            {:sequence, [literal: "a", literal: "b", literal: "c"]}
          ]
        ]
      )
    end
  end
end
