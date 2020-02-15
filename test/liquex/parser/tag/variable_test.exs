defmodule Liquex.Parser.Tag.VariableTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  describe "assign_tag" do
    test "parse simple assign" do
      "{% assign a = 5 %}"
      |> assert_parse(variable: [assign: [left: "a", right: [literal: 5]]])
    end

    test "parse field assign" do
      "{% assign a = b %}"
      |> assert_parse(variable: [assign: [left: "a", right: [field: [key: "b"]]]])
    end
  end

  describe "capture_tag" do
    test "parse simple capture" do
      "{% capture a %}This is a test{% endcapture %}"
      |> assert_parse(variable: [capture: [identifier: "a", contents: [text: "This is a test"]]])
    end
  end

  describe "incrementer_tag" do
    test "parse increment" do
      "{% increment a %}"
      |> assert_parse(variable: [increment: [identifier: "a", by: 1]])
    end

    test "parse decrement" do
      "{% decrement a %}"
      |> assert_parse(variable: [increment: [identifier: "a", by: -1]])
    end
  end
end
