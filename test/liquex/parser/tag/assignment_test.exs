defmodule Liquex.Parser.Tag.AssignmentTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  describe "assign_tag" do
    test "parse simple assign" do
      "{% assign a = 5 %}"
      |> assert_parse(assign: [field: [key: "a"], literal: 5])

      "{% assign a.b = 5 %}"
      |> assert_parse(assign: [field: [key: "a", key: "b"], literal: 5])
    end

    test "parse field assign" do
      "{% assign a = b %}"
      |> assert_parse(assign: [field: [key: "a"], field: [key: "b"]])
    end
  end
end
