defmodule Liquex.RepresentableTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Liquex.Representable

  defmodule TestStruct do
    defstruct [:name]
  end

  describe "represent/2" do
    test "Converts map to string key map",
      do: assert(%{"test" => "hello"} == Representable.represent(%{test: "hello"}))

    test "Converts struct to string key map",
      do: assert(%{"name" => "John"} == Representable.represent(%TestStruct{name: "John"}))

    test "Converts list of maps",
      do: assert([%{"test" => "hello"}] == Representable.represent([%{test: "hello"}]))

    test "Converts nested maps" do
      assert(
        %{"test" => %{"child" => "map"}, "value" => "hello"} ==
          Representable.represent(%{test: %{child: "map"}, value: "hello"})
      )
    end

    test "Converts nested maps lazily" do
      assert(
        %{"test" => func, "value" => "hello"} =
          Representable.represent(%{test: %{child: "map"}, value: "hello"}, true)
      )

      assert %{"child" => "map"} == func.()
    end

    test "converts deeply nested structs" do
      assert(
        %{"name" => %{"name" => "John"}} ==
          Representable.represent(%TestStruct{name: %TestStruct{name: "John"}})
      )
    end

    test "converts deeply nested structs lazily" do
      assert(
        %{"name" => func} =
          Representable.represent(%TestStruct{name: %TestStruct{name: "John"}}, true)
      )

      assert(%{"name" => "John"} = func.())
    end

    test "does not convert NaiveDateTime" do
      assert %{"date" => ~D[2020-01-01]} == Representable.represent(%{date: ~D[2020-01-01]}, true)
    end

    test "does not convert basic types", do: assert(5 == Representable.represent(5))
  end
end
