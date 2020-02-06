defmodule Liquex.ParserTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  test "greets the world" do
    assert_parse("Hello World", text: ["Hello World"])
  end
end
