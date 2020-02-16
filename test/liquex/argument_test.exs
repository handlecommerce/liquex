defmodule Liquex.ArgumentTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Liquex.Argument
  alias Liquex.Context

  describe "eval" do
    test "evaluate literal" do
      assert 5 == Argument.eval([literal: 5], %Context{})
    end

    test "evaluate unkown field" do
      assert nil == Argument.eval([field: [key: "i"]], %Context{})
      assert nil == Argument.eval([field: [key: "a", key: "b"]], %Context{})
    end

    test "evaluate with known field" do
      assert 5 == Argument.eval([field: [key: "i"]], Context.new(%{"i" => 5}))
      assert 5 == Argument.eval([field: [key: "a", key: "b"]], Context.new(%{"a" => %{"b" => 5}}))
    end

    test "evaluate with array field" do
      obj = Context.new(%{"field" => [%{}, %{"child" => 5}]})

      assert 5 == Argument.eval([field: [key: "field", accessor: 1, key: "child"]], obj)
    end

    test "evaluate with array.first" do
      obj = Context.new(%{"field" => [%{"child" => 5}]})

      assert 5 == Argument.eval([field: [key: "field", key: "first", key: "child"]], obj)
    end

    test "evaluate with array.size" do
      obj = Context.new(%{"field" => [1, 2, 3, 4, 5]})

      assert 5 == Argument.eval([field: [key: "field", key: "size"]], obj)
    end

    test "evaluate with out of bounds array field" do
      obj = Context.new(%{"field" => [%{}, %{"child" => 5}]})
      assert nil == Argument.eval([field: [key: "field", accessor: 5, key: "child"]], obj)
    end
  end
end
