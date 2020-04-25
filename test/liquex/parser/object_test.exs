defmodule Liquex.Parser.ObjectTest do
  @moduledoc false

  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  test "handles simple filter" do
    assert_parse(
      "{{ true | not }}",
      object: [literal: true, filters: [filter: ["not", arguments: []]]]
    )
  end

  test "parses filter with single argument" do
    assert_parse(
      "{{ 123.45 | money: 'USD' }}",
      object: [literal: 123.45, filters: [filter: ["money", arguments: [literal: "USD"]]]]
    )
  end

  test "parses filter with multiple arguments" do
    assert_parse(
      "{{ 123.45 | money: 'USD', format }}",
      object: [
        literal: 123.45,
        filters: [filter: ["money", arguments: [literal: "USD", field: [key: "format"]]]]
      ]
    )
  end

  test "parses filter with key/value arguments" do
    assert_parse(
      "{{ product | img_url: '400x400', crop: 'bottom' }}",
      object: [
        field: [key: "product"],
        filters: [
          filter: [
            "img_url",
            arguments: [literal: "400x400", keyword: ["crop", literal: "bottom"]]
          ]
        ]
      ]
    )
  end

  test "parses filter with key/value arguments as first argument" do
    assert_parse(
      "{{ product | img_url: crop: 'bottom' }}",
      object: [
        field: [key: "product"],
        filters: [
          filter: [
            "img_url",
            arguments: [keyword: ["crop", literal: "bottom"]]
          ]
        ]
      ]
    )
  end

  test "parses multiple filters" do
    assert_parse("{{ 'adam!' | capitalize | prepend: 'Hello ' }}",
      object: [
        literal: "adam!",
        filters: [
          filter: ["capitalize", arguments: []],
          filter: ["prepend", arguments: [literal: "Hello "]]
        ]
      ]
    )
  end
end
