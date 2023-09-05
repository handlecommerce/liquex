defmodule Liquex.ExpressionTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Liquex.Context
  alias Liquex.Expression

  describe "eval truthy" do
    def expression_value({value, _context}), do: value

    test "literal" do
      assert Expression.eval([literal: 123], %Context{}) |> expression_value()
      assert Expression.eval([literal: true], %Context{}) |> expression_value()
      refute Expression.eval([literal: false], %Context{}) |> expression_value()
      refute Expression.eval([literal: nil], %Context{}) |> expression_value()
    end

    test "field" do
      assert Expression.eval([field: [key: "field"]], Context.new(%{"field" => 1}))
             |> expression_value()

      refute Expression.eval([field: [key: "field"]], Context.new(%{"field" => nil}))
             |> expression_value()
    end

    test "standard expression operators" do
      assert eval(1, :==, 2) == false
      assert eval(1, :==, 1) == true
      assert eval(1, :!=, 2) == true
      assert eval(1, :!=, 1) == false
      assert eval(1, :<, 2) == true
      assert eval(1, :<, 1) == false
      assert eval(1, :>, 2) == false
      assert eval(2, :>, 1) == true
      assert eval(1, :>=, 1) == true
      assert eval(1, :>=, 0) == true
      assert eval(1, :>=, 2) == false
      assert eval(1, :<=, 1) == true
      assert eval(1, :<=, 0) == false
      assert eval(1, :<=, 2) == true
      assert eval(0, :<=, nil) == false
      assert eval(1.0, :<, nil) == false
      assert eval(nil, :>=, 1.0) == false
      assert eval(nil, :>, 0) == false
      assert eval("Beer Pack", :contains, "Pack") == true
      assert eval("Meat", :contains, "Pack") == false
      assert eval(["Beer", "Pack"], :contains, "Pack") == true
      assert eval(["Meat"], :contains, "Pack") == false
      assert eval(nil, :contains, "Pack") == false
      assert eval("Meat", :contains, nil) == false
      assert eval("12345", :contains, 234) == true
    end
  end

  describe "eval boolean logic" do
    test "and" do
      assert Expression.eval([{:literal, true}, :and, {:literal, true}], %Context{})
             |> expression_value()

      refute Expression.eval([{:literal, true}, :and, {:literal, false}], %Context{})
             |> expression_value()
    end

    test "or" do
      assert Expression.eval([{:literal, true}, :or, {:literal, true}], %Context{})
             |> expression_value()

      assert Expression.eval([{:literal, true}, :or, {:literal, false}], %Context{})
             |> expression_value()

      refute Expression.eval([{:literal, false}, :or, {:literal, false}], %Context{})
             |> expression_value()
    end

    test "eval boolean logic in reverse" do
      assert Expression.eval(
               [[literal: true], :or, [literal: true], :and, [literal: false]],
               %Context{}
             )
             |> expression_value()
    end

    test "eval boolean logic with fields" do
      assert Expression.eval(
               [
                 [field: [key: "field1"]],
                 :or,
                 [field: [key: "field2"]]
               ],
               Context.new(%{"field1" => true, "field2" => nil})
             )
             |> expression_value()
    end
  end

  def eval(left, op, right),
    do:
      Expression.eval([left: [literal: left], op: op, right: [literal: right]], %Context{})
      |> expression_value()
end
