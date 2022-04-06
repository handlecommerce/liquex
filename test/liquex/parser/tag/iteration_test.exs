defmodule Liquex.Parser.Tag.IterationTest do
  @moduledoc false

  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  describe "tablerow_tag" do
    test "parse simple tablerow" do
      "{% tablerow product in collection %}{{ product }}{% endtablerow %}"
      |> assert_parse(
        iteration: [
          tablerow: [
            identifier: "product",
            collection: [field: [key: "collection"]],
            parameters: [],
            contents: [object: [field: [key: "product"], filters: []]]
          ]
        ]
      )
    end

    test "parse tablerow with parameters" do
      "{% tablerow product in collection cols:2 limit:3 offset:2 %}{{ product }}{% endtablerow %}"
      |> assert_parse(
        iteration: [
          tablerow: [
            identifier: "product",
            collection: [field: [key: "collection"]],
            parameters: [cols: 2, limit: 3, offset: 2],
            contents: [object: [field: [key: "product"], filters: []]]
          ]
        ]
      )
    end
  end
end
