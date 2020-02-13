defmodule Liquex.Parser.TagTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  test "parses comment" do
    assert_parse("Hello {% comment %}Ignored text{% endcomment %} World",
      text: "Hello ",
      text: " World"
    )
  end

  test "parses raw" do
    assert_parse("{% raw %} {{ test }} {% endraw %}",
      text: [" {{ test }} "]
    )

    assert_parse("{% raw %} {{ test }} {% stuff %}{% endraw %}",
      text: [" {{ test }} "]
    )
  end
end
