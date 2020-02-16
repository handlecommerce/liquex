defmodule Liquex.FilterTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Liquex.Filter
  doctest Liquex.Filter

  test "apply" do
    assert 5 == Filter.apply(-5, {:filter, ["abs", {:arguments, []}]}, %{})
  end
end
