defmodule Liquex.ParserTest do
  use ExUnit.Case

  test "greets the world" do
    assert_parse("Hello World", text: ["Hello World"])
  end

  def assert_parse(doc, match) do
    assert {:ok, ^match, "", _, _, _} = Liquex.Parser.parse(doc)
  end
end
