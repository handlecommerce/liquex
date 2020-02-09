defmodule Liquex.Parser.Tag.VariableTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  describe "assign_tag" do
    test "parse simple assign" do
      "{% assign a = 5 %}"
      |> assert_parse(variable: [assign: [field: [key: "a"], literal: 5]])

      "{% assign a.b = 5 %}"
      |> assert_parse(variable: [assign: [field: [key: "a", key: "b"], literal: 5]])
    end

    test "parse field assign" do
      "{% assign a = b %}"
      |> assert_parse(variable: [assign: [field: [key: "a"], field: [key: "b"]]])
    end
  end

  describe "capture_tag" do
    test "parse simple capture" do
      "{% capture a.b %}This is a test{% endcapture %}"
      |> assert_parse(
        variable: [capture: [field: [key: "a", key: "b"], contents: [text: "This is a test"]]]
      )
    end
  end

  describe "incrementer_tag" do
    test "parse increment" do
      "{% increment a %}"
      |> assert_parse(variable: [increment: [field: [key: "a"], by: 1]])

      "{% increment a.b %}"
      |> assert_parse(variable: [increment: [field: [key: "a", key: "b"], by: 1]])
    end

    test "parse decrement" do
      "{% decrement a %}"
      |> assert_parse(variable: [increment: [field: [key: "a"], by: -1]])

      "{% decrement a.b %}"
      |> assert_parse(variable: [increment: [field: [key: "a", key: "b"], by: -1]])
    end
  end
end
