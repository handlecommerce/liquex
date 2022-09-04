defmodule Liquex.FilterTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Liquex.Filter
  doctest Liquex.Filter

  test "apply" do
    assert 5 == Filter.apply(-5, {:filter, ["abs", {:arguments, []}]}, %{})
  end

  test "date" do
    assert "2022" ==
             Filter.apply(
               ~D[2022-01-01],
               {:filter, ["date", {:arguments, [{:literal, "%Y"}]}]},
               %{}
             )

    assert nil ==
             Filter.apply(
               nil,
               {:filter, ["date", {:arguments, [{:literal, "%Y"}]}]},
               %{}
             )
  end
end
