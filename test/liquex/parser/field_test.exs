defmodule Liquex.Parser.FieldTest do
  @moduledoc false

  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  test "simple field" do
    assert_parse("{{ field }}", [
      {{:tag, Liquex.Tag.ObjectTag}, [field: [key: "field"], filters: []]}
    ])
  end

  test "nested field" do
    assert_parse(
      "{{ field.child }}",
      [{{:tag, Liquex.Tag.ObjectTag}, [field: [key: "field", key: "child"], filters: []]}]
    )
  end

  test "field with question mark at end" do
    assert_parse("{{ field? }}", [
      {{:tag, Liquex.Tag.ObjectTag}, [field: [key: "field?"], filters: []]}
    ])
  end

  test "field with hyphens" do
    assert_parse("{{ field-with-hyphens }}", [
      {{:tag, Liquex.Tag.ObjectTag}, [field: [key: "field-with-hyphens"], filters: []]}
    ])
  end

  test "with accessors" do
    assert_parse(
      "{{ field[1] }}",
      [
        {{:tag, Liquex.Tag.ObjectTag},
         [field: [key: "field", accessor: {:literal, 1}], filters: []]}
      ]
    )
  end

  test "with accessor and child" do
    assert_parse(
      "{{ field[1].child }}",
      [
        {{:tag, Liquex.Tag.ObjectTag},
         [field: [key: "field", accessor: {:literal, 1}, key: "child"], filters: []]}
      ]
    )

    assert_parse(
      "{{ field.child[0] }}",
      [
        {{:tag, Liquex.Tag.ObjectTag},
         [field: [key: "field", key: "child", accessor: {:literal, 0}], filters: []]}
      ]
    )

    assert_parse(
      "{{ field[1].child[0] }}",
      [
        {
          {:tag, Liquex.Tag.ObjectTag},
          field: [key: "field", accessor: {:literal, 1}, key: "child", accessor: {:literal, 0}],
          filters: []
        }
      ]
    )
  end
end
