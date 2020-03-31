defmodule Liquex.ComparisonTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  test "run examples" do
    File.ls!("test/integration/cases/")
    |> Enum.filter(&String.ends_with?(&1, ".liquid"))
    |> Enum.each(&assert_match_liquid("test/integration/cases/#{&1}"))
  end
end
