defmodule Liquex.ArgumentTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Liquex.Argument
  alias Liquex.Context

  describe "eval" do
    test "evaluate literal" do
      assert 5 == Argument.eval([literal: 5], Context.new(%{}))
    end

    test "evaluate unknown field" do
      assert nil == Argument.eval([field: [key: "i"]], Context.new(%{}))
      assert nil == Argument.eval([field: [key: "a", key: "b"]], Context.new(%{}))
    end

    test "evaluate with known field" do
      assert 5 == Argument.eval([field: [key: "i"]], Context.new(%{"i" => 5}))
      assert 5 == Argument.eval([field: [key: "a", key: "b"]], Context.new(%{"a" => %{"b" => 5}}))
    end

    test "evaluate with atom keys" do
      assert 5 == Argument.eval([field: [key: "i"]], Context.new(%{i: 5}))
      assert 5 == Argument.eval([field: [key: "a", key: "b"]], Context.new(%{a: %{b: 5}}))
    end

    test "evaluate with array field" do
      obj = Context.new(%{"field" => [%{}, %{"child" => 5}]})

      assert 5 ==
               Argument.eval([field: [key: "field", accessor: {:literal, 1}, key: "child"]], obj)
    end

    test "evaluate with array.first" do
      obj = Context.new(%{"field" => [%{"child" => 5}]})

      assert 5 == Argument.eval([field: [key: "field", key: "first", key: "child"]], obj)
    end

    test "evaluate with array.last" do
      obj = Context.new(%{"field" => [1, 2, 3, 4, 5]})

      assert 5 == Argument.eval([field: [key: "field", key: "last"]], obj)
    end

    test "evaluate with array.size" do
      obj = Context.new(%{"field" => [1, 2, 3, 4, 5]})

      assert 5 == Argument.eval([field: [key: "field", key: "size"]], obj)
    end

    test "evaluate with string.size" do
      obj = Context.new(%{"field" => "String"})

      assert 6 == Argument.eval([field: [key: "field", key: "size"]], obj)
    end

    test "evaluate with out of bounds array field" do
      obj = Context.new(%{"field" => [%{}, %{"child" => 5}]})

      assert nil ==
               Argument.eval([field: [key: "field", accessor: {:literal, 5}, key: "child"]], obj)
    end

    test "anonymous function field" do
      obj = Context.new(%{"field" => fn -> 5 end})
      assert 5 == Argument.eval([field: [key: "field"]], obj)
    end
  end

  describe "assign" do
    test "assign new value" do
      context = Argument.assign(Context.new(%{}), [field: [key: "i"]], 5)
      assert 5 == Argument.eval([field: [key: "i"]], context)
    end

    test "assign new nested value" do
      context =
        %{"a" => %{}}
        |> Context.new()
        |> Argument.assign([field: [key: "a", key: "b"]], 5)

      assert 5 == Argument.eval([field: [key: "a", key: "b"]], context)
    end

    test "assign in list" do
      context =
        %{"field" => [1, 2, 3]}
        |> Context.new()
        |> Argument.assign([field: [key: "field", accessor: 1]], 9)

      assert [1, 9, 3] == Argument.eval([field: [key: "field"]], context)
    end
  end
end
