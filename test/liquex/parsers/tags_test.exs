defmodule Liquex.Parsers.TagsTest do
  use ExUnit.Case

  test "parses comment" do
    assert_parse("Hello {% comment %}Ignored text{% endcomment %} World",
      text: ["Hello "],
      text: [" World"]
    )
  end

  test "parses raw" do
    assert_parse("{% raw %} {{ test }} {% endraw %}",
      text: [" {{ test }} "]
    )
  end

  def assert_parse(doc, match) do
    assert {:ok, ^match, "", _, _, _} = Liquex.Parser.parse(doc)
  end
end
