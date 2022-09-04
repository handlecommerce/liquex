defmodule Liquex.ContextTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Liquex.Context

  describe "assign/3" do
    test "it assigns object to a key" do
      context =
        %{}
        |> Context.new()
        |> Context.assign("test", "value")
        |> Context.assign("another", "value")

      assert Access.get(context, "test") == "value"
      assert Access.get(context, "another") == "value"
    end

    test "it assigns with atom keys" do
      context =
        %{}
        |> Context.new()
        |> Context.assign(:test, "value")
        |> Context.assign(:another, "value")

      assert Access.get(context, :test, "value")
      assert Access.get(context, :another, "value")
    end

    test "it assigns with indifferent access" do
      context =
        %{}
        |> Context.new()
        |> Context.assign(:test, 1)
        |> Context.assign("test", 2)

      assert Access.get(context, :test) == 2
      assert Access.get(context, "test") == 2

      context =
        %{}
        |> Context.new()
        |> Context.assign("test", 1)
        |> Context.assign(:test, 2)

      assert Access.get(context, :test) == 2
      assert Access.get(context, "test") == 2
    end
  end

  describe "push_error/2" do
    test "it pushes error into errors" do
      context =
        %{}
        |> Context.new()
        |> Context.push_error("error 1")
        |> Context.push_error("error 2")

      assert context.errors == ["error 2", "error 1"]
    end
  end

  describe "push_scope" do
    test "it creates a new scope" do
      context = Context.new(%{})

      assert context.scope.stack == [%{}]

      context = Context.push_scope(context)
      assert context.scope.stack == [%{}, %{}]
    end

    test "assign into new scope" do
      context =
        %{a: 1}
        |> Context.new()
        |> Context.push_scope()
        |> Context.assign(:b, 2)
        |> Context.push_scope()
        |> Context.assign(:c, 3)

      assert Context.fetch(context, :a) == {:ok, 1}
      assert Context.fetch(context, :b) == {:ok, 2}
      assert Context.fetch(context, :c) == {:ok, 3}

      context = Context.pop_scope(context)

      assert Context.fetch(context, :a) == {:ok, 1}
      assert Context.fetch(context, :b) == {:ok, 2}
      assert Context.fetch(context, :c) == :error

      context = Context.pop_scope(context)

      assert Context.fetch(context, :a) == {:ok, 1}
      assert Context.fetch(context, :b) == :error
      assert Context.fetch(context, :c) == :error
    end
  end

  describe "pop_scope" do
    test "pop scope" do
      context = Context.new(%{})

      assert context.scope.stack == [%{}]

      context = Context.push_scope(context)
      assert context.scope.stack == [%{}, %{}]
      context = Context.pop_scope(context)
      assert context.scope.stack == [%{}]
      context = Context.pop_scope(context)
      assert context.scope.stack == [%{}]
    end
  end
end
