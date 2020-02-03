defmodule LiquexTest do
  use ExUnit.Case
  doctest Liquex

  test "greets the world" do
    assert Liquex.hello() == :world
  end
end
