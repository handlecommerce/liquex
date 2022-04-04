defmodule Liquex.Parser.WhitespaceTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  test "Parses with {%- and -%} properly" do
    assert_parse(
      "Hello {%- comment -%}Ignored text{%- endcomment -%} World",
      [
        {:text, "Hello"},
        {{:tag, Liquex.Tag.Comment}, []},
        {:text, "World"}
      ]
    )
  end

  test "Parses with {{- and -}} properly" do
    assert_parse("{{- 'Hello World' -}}  ",
      object: [literal: "Hello World", filters: []]
    )
  end

  test "removes spaces after -%}" do
    assert_parse(
      "{% raw -%}\n  This is a test{% endraw %}",
      [{{:tag, Liquex.Tag.Raw}, ["This is a test"]}]
    )
  end
end
