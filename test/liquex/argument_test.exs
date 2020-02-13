defmodule Liquex.ArgumentTest do
  use ExUnit.Case, async: true

  alias Liquex.Argument

  describe "eval" do
    test "evaluate literal" do
      assert 5 == Argument.eval([literal: 5], %{})
    end

    test "evaluate unkown field" do
      assert nil == Argument.eval([field: [key: "i"]], %{})
      assert nil == Argument.eval([field: [key: "a", key: "b"]], %{})
    end

    test "evaluate with known field" do
      assert 5 == Argument.eval([field: [key: "i"]], %{"i" => 5})
      assert 5 == Argument.eval([field: [key: "a", key: "b"]], %{"a" => %{"b" => 5}})
    end

    test "evaluate with array field" do
      obj = %{"field" => [%{}, %{"child" => 5}]}

      assert 5 == Argument.eval([field: [key: "field", accessor: 1, key: "child"]], obj)
    end

    test "evaluate with out of bounds array field" do
      obj = %{"field" => [%{}, %{"child" => 5}]}
      assert nil == Argument.eval([field: [key: "field", accessor: 5, key: "child"]], obj)
    end
  end
end
