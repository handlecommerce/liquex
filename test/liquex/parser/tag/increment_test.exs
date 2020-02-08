defmodule Liquex.Parser.Tag.IncrementTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  describe "incrementer_tag" do
    test "parse increment" do
      "{% increment a %}"
      |> assert_parse(increment: [field: [key: "a"], by: 1])

      "{% increment a.b %}"
      |> assert_parse(increment: [field: [key: "a", key: "b"], by: 1])
    end

    test "parse decrement" do
      "{% decrement a %}"
      |> assert_parse(increment: [field: [key: "a"], by: -1])

      "{% decrement a.b %}"
      |> assert_parse(increment: [field: [key: "a", key: "b"], by: -1])
    end
  end
end
