defmodule Liquex.Parser.FieldTest do
  @moduledoc false

  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  test "simple field" do
    assert_parse("{{ field }}", object: [field: [key: "field"], filters: []])
    assert_parse("{{ f }}", object: [field: [key: "f"], filters: []])
  end

  test "nested field" do
    assert_parse(
      "{{ field.child }}",
      object: [field: [key: "field", key: "child"], filters: []]
    )
  end

  test "with accessors" do
    assert_parse(
      "{{ field[1] }}",
      object: [field: [key: "field", accessor: 1], filters: []]
    )
  end

  test "with accessor and child" do
    assert_parse(
      "{{ field[1].child }}",
      object: [field: [key: "field", accessor: 1, key: "child"], filters: []]
    )

    assert_parse(
      "{{ field.child[0] }}",
      object: [field: [key: "field", key: "child", accessor: 0], filters: []]
    )

    assert_parse(
      "{{ field[1].child[0] }}",
      object: [field: [key: "field", accessor: 1, key: "child", accessor: 0], filters: []]
    )
  end
end
