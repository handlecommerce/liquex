defmodule Liquex.Parser.WhitespaceTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  test "Parses with {%- and -%} properly" do
    assert_parse(
      "Hello {%- comment -%}Ignored text{%- endcomment -%} World",
      [
        {:text, "Hello"},
        {{:tag, Liquex.Tag.CommentTag}, []},
        {:text, "World"}
      ]
    )
  end

  test "Parses with {{- and -}} properly" do
    assert_parse(
      "{{- 'Hello World' -}}  ",
      [{{:tag, Liquex.Tag.ObjectTag}, [literal: "Hello World", filters: []]}]
    )
  end

  test "removes spaces after -%}" do
    assert_parse(
      "{% raw -%}\n  This is a test{% endraw %}",
      [{{:tag, Liquex.Tag.RawTag}, ["This is a test"]}]
    )
  end
end
