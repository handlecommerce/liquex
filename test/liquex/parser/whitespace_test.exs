defmodule Liquex.Parser.WhitespaceTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  test "Parses with {%- and -%} properly" do
    assert_parse("Hello {%- comment -%}Ignored text{%- endcomment -%} World",
      text: "Hello ",
      text: "World"
    )
  end

  test "Parses with {{- and -}} properly" do
    assert_parse("{{- 'Hello World' -}}  ",
      object: [literal: "Hello World", filters: []]
    )
  end

  test "removes spaces after -%}" do
    assert_parse("{% raw -%}\n  This is a test{% endraw %}",
      text: ["This is a test"]
    )
  end
end
