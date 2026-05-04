defmodule Liquex.ExpressionTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Liquex.Context
  alias Liquex.Expression

  describe "eval truthy" do
    test "literal" do
      assert eval_value([literal: 123], %Context{})
      assert eval_value([literal: true], %Context{})
      refute eval_value([literal: false], %Context{})
      refute eval_value([literal: nil], %Context{})
    end

    test "field" do
      assert eval_value([field: [key: "field"]], Context.new(%{"field" => 1}))
      refute eval_value([field: [key: "field"]], Context.new(%{"field" => nil}))
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
      assert eval_value([{:literal, true}, :and, {:literal, true}], %Context{})
      refute eval_value([{:literal, true}, :and, {:literal, false}], %Context{})
    end

    test "or" do
      assert eval_value([{:literal, true}, :or, {:literal, true}], %Context{})
      assert eval_value([{:literal, true}, :or, {:literal, false}], %Context{})
      refute eval_value([{:literal, false}, :or, {:literal, false}], %Context{})
    end

    test "eval boolean logic in reverse" do
      assert eval_value(
               [[literal: true], :or, [literal: true], :and, [literal: false]],
               %Context{}
             )
    end

    test "eval boolean logic with fields" do
      assert eval_value(
               [
                 [field: [key: "field1"]],
                 :or,
                 [field: [key: "field2"]]
               ],
               Context.new(%{"field1" => true, "field2" => nil})
             )
    end
  end

  defp eval_value(ast, context), do: Expression.eval(ast, context) |> elem(0)

  def eval(left, op, right),
    do:
      Expression.eval([left: [literal: left], op: op, right: [literal: right]], %Context{})
      |> elem(0)
end
