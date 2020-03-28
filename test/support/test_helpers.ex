defmodule Liquex.TestHelpers do
  @moduledoc false

  import ExUnit.Assertions

  def assert_parse(doc, match), do: assert({:ok, ^match, "", _, _, _} = Liquex.Parser.parse(doc))
end
