defmodule Liquex.TestHelpers do
  import ExUnit.Assertions

  def assert_parse(doc, match) do
    assert {:ok, ^match, "", _, _, _} = Liquex.Parser.parse(doc)
  end
end
