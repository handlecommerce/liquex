defmodule Liquex.ScopeTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Liquex.Scope

  describe "new" do
    test "creates a scope" do
      assert Scope.new().stack == [%{}]
      assert Scope.new(%{a: :b}).stack == [%{a: :b}]
    end
  end

  describe "push" do
    test "push a new scope" do
      scope = Scope.new()

      assert Scope.push(scope).stack == [%{}, %{}]
      assert Scope.push(scope, %{a: :b}).stack == [%{a: :b}, %{}]
    end
  end

  describe "pop" do
    test "pops a scope off the stack" do
      assert Scope.new()
             |> Scope.push(%{a: 1})
             |> Scope.pop() == %Scope{stack: [%{}]}
    end

    test "doesn't allow a blank scope stack" do
      assert Scope.new()
             |> Scope.push(%{a: 1})
             |> Scope.pop()
             |> Scope.pop() == %Scope{stack: [%{}]}
    end
  end

  describe "assign" do
    test "assigns a new variable" do
      scope =
        Scope.new()
        |> Scope.assign(:a, 1)

      assert scope.stack == [%{a: 1}]
    end

    test "assigns to an existing variable" do
      scope =
        Scope.new(%{a: 1})
        |> Scope.assign(:a, 2)

      assert scope.stack == [%{a: 2}]
    end

    test "assigns to a variable higher in the stack" do
      scope =
        Scope.new(%{a: 1})
        |> Scope.push()
        |> Scope.assign(:a, 2)

      assert scope.stack == [%{}, %{a: 2}]

      scope =
        Scope.new(%{outer: :scope})
        |> Scope.push(%{a: 1})
        |> Scope.push(%{inner: :scope})
        |> Scope.assign(:a, 2)

      assert scope.stack == [%{inner: :scope}, %{a: 2}, %{outer: :scope}]
    end
  end
end
