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

      assert context.variables == %{"test" => "value", "another" => "value"}
    end

    test "it assigns with atom keys" do
      context =
        %{}
        |> Context.new()
        |> Context.assign(:test, "value")
        |> Context.assign(:another, "value")

      assert context.variables == %{test: "value", another: "value"}
    end

    test "it assigns with indifferent access" do
      context =
        %{}
        |> Context.new()
        |> Context.assign(:test, 1)
        |> Context.assign("test", 2)

      assert context.variables == %{test: 2}

      context =
        %{}
        |> Context.new()
        |> Context.assign("test", 1)
        |> Context.assign(:test, 2)

      assert context.variables == %{"test" => 2}
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
end
