defmodule Liquex.Parser.TagTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  test "parses comment" do
    assert_parse(
      "Hello {% comment %}Ignored text{% endcomment %} World",
      [{:text, "Hello "}, {{:tag, Liquex.Parser.Tag.Comment}, []}, {:text, " World"}]
    )
  end

  test "parses raw" do
    assert_parse(
      "{% raw %} {{ test }} {% endraw %}",
      [{{:tag, Liquex.Parser.Tag.Raw}, [" {{ test }} "]}]
    )

    assert_parse(
      "{% raw %} {{ test }} {% tag %} {% endraw %}",
      [{{:tag, Liquex.Parser.Tag.Raw}, [" {{ test }} {% tag %} "]}]
    )
  end
end
