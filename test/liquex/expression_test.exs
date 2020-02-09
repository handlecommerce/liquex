defmodule Liquex.ExpressionTest do
  use ExUnit.Case, async: true

  alias Liquex.Expression

  describe "eval truthy" do
    test "literal" do
      assert Expression.eval({:literal, 123}, %{})
      assert Expression.eval({:literal, true}, %{})
      refute Expression.eval({:literal, false}, %{})
      refute Expression.eval({:literal, nil}, %{})
    end

    test "field" do
      assert Expression.eval({:field, [key: "field"]}, %{"field" => 1})
      refute Expression.eval({:field, [key: "field"]}, %{"field" => nil})
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
    end
  end

  describe "eval boolean logic" do
    test "and" do
      assert Expression.eval([{:literal, true}, :and, {:literal, true}], %{})
      refute Expression.eval([{:literal, true}, :and, {:literal, false}], %{})
    end

    test "or" do
      assert Expression.eval([{:literal, true}, :or, {:literal, true}], %{})
      assert Expression.eval([{:literal, true}, :or, {:literal, false}], %{})
      refute Expression.eval([{:literal, false}, :or, {:literal, false}], %{})
    end

    test "eval boolean logic in reverse" do
      assert Expression.eval(
               [{:literal, true}, :or, {:literal, true}, :and, {:literal, false}],
               %{}
             )
    end

    test "eval boolean logic with fields" do
      assert Expression.eval(
               [
                 {:field, [key: "field1"]},
                 :or,
                 {:field, [key: "field2"]}
               ],
               %{"field1" => true, "field2" => nil}
             )
    end
  end

  def eval(left, op, right), do: Expression.eval({{:literal, left}, op, {:literal, right}}, %{})
end
