defmodule Liquex.MathTest do
  use ExUnit.Case, async: true

  alias Liquex.Math

  @inf Math.infinity()
  @ninf Math.neg_infinity()
  @nan Math.nan()

  describe "rendering" do
    test "to_string renders the IEEE labels Liquid uses" do
      assert to_string(@inf) == "Infinity"
      assert to_string(@ninf) == "-Infinity"
      assert to_string(@nan) == "NaN"
    end

    test "inspect is human-readable" do
      assert inspect(@inf) == "#Liquex.Math<Infinity>"
      assert inspect(@ninf) == "#Liquex.Math<-Infinity>"
      assert inspect(@nan) == "#Liquex.Math<NaN>"
    end
  end

  describe "predicates" do
    test "special?" do
      assert Math.special?(@inf)
      assert Math.special?(@ninf)
      assert Math.special?(@nan)
      refute Math.special?(0)
      refute Math.special?(0.0)
      refute Math.special?(nil)
      refute Math.special?("Infinity")
    end

    test "nan? matches only NaN" do
      assert Math.nan?(@nan)
      refute Math.nan?(@inf)
      refute Math.nan?(@ninf)
      refute Math.nan?(0)
    end

    test "infinite? matches +/- infinity but not NaN" do
      assert Math.infinite?(@inf)
      assert Math.infinite?(@ninf)
      refute Math.infinite?(@nan)
      refute Math.infinite?(1.0)
    end
  end

  describe "from_zero_div" do
    test "preserves sign" do
      assert Math.from_zero_div(5) == @inf
      assert Math.from_zero_div(-5) == @ninf
      assert Math.from_zero_div(0) == @nan
      assert Math.from_zero_div(0.0) == @nan
    end

    test "passes through specials" do
      assert Math.from_zero_div(@inf) == @inf
      assert Math.from_zero_div(@ninf) == @ninf
      assert Math.from_zero_div(@nan) == @nan
    end
  end

  describe "add (IEEE 754 propagation)" do
    test "regular numbers" do
      assert Math.add(2, 3) == 5
      assert Math.add(2.5, 0.5) == 3.0
    end

    test "infinity dominates finite" do
      assert Math.add(@inf, 1) == @inf
      assert Math.add(1, @inf) == @inf
      assert Math.add(@ninf, 1) == @ninf
      assert Math.add(1, @ninf) == @ninf
    end

    test "infinity + infinity = infinity (same sign)" do
      assert Math.add(@inf, @inf) == @inf
      assert Math.add(@ninf, @ninf) == @ninf
    end

    test "infinity + (-infinity) is NaN" do
      assert Math.add(@inf, @ninf) == @nan
      assert Math.add(@ninf, @inf) == @nan
    end

    test "NaN absorbs everything" do
      assert Math.add(@nan, 1) == @nan
      assert Math.add(1, @nan) == @nan
      assert Math.add(@nan, @inf) == @nan
      assert Math.add(@inf, @nan) == @nan
      assert Math.add(@nan, @nan) == @nan
    end
  end

  describe "sub" do
    test "infinity - infinity is NaN" do
      assert Math.sub(@inf, @inf) == @nan
      assert Math.sub(@ninf, @ninf) == @nan
    end

    test "infinity - (-infinity) is infinity" do
      assert Math.sub(@inf, @ninf) == @inf
      assert Math.sub(@ninf, @inf) == @ninf
    end

    test "finite operands" do
      assert Math.sub(5, 3) == 2
      assert Math.sub(@inf, 5) == @inf
      assert Math.sub(5, @inf) == @ninf
    end
  end

  describe "mul" do
    test "regular numbers" do
      assert Math.mul(2, 3) == 6
    end

    test "infinity * 0 is NaN" do
      assert Math.mul(@inf, 0) == @nan
      assert Math.mul(0, @inf) == @nan
      assert Math.mul(@ninf, 0) == @nan
      assert Math.mul(@inf, +0.0) == @nan
    end

    test "infinity * positive = infinity (sign-preserving)" do
      assert Math.mul(@inf, 2) == @inf
      assert Math.mul(@inf, -2) == @ninf
      assert Math.mul(@ninf, 2) == @ninf
      assert Math.mul(@ninf, -2) == @inf
    end

    test "infinity * infinity" do
      assert Math.mul(@inf, @inf) == @inf
      assert Math.mul(@ninf, @ninf) == @inf
      assert Math.mul(@inf, @ninf) == @ninf
      assert Math.mul(@ninf, @inf) == @ninf
    end

    test "NaN absorbs" do
      assert Math.mul(@nan, 1) == @nan
      assert Math.mul(@nan, @inf) == @nan
    end
  end

  describe "divide" do
    test "regular division" do
      assert Math.divide(6, 2) == 3.0
      assert Math.divide(7, 2) == 3.5
    end

    test "integer divisor zero returns sentinel for filter to convert" do
      assert Math.divide(5, 0) == {:zero_division}
    end

    test "float divisor zero produces signed infinity / NaN" do
      assert Math.divide(5, 0.0) == @inf
      assert Math.divide(-5, 0.0) == @ninf
      assert Math.divide(0, 0.0) == @nan
      assert Math.divide(0.0, 0.0) == @nan
    end

    test "finite / infinity is 0.0 (Float)" do
      assert Math.divide(1, @inf) === 0.0
      assert Math.divide(-1, @inf) === 0.0
    end

    test "infinity / finite preserves sign" do
      assert Math.divide(@inf, 2) == @inf
      assert Math.divide(@inf, -2) == @ninf
      assert Math.divide(@ninf, 2) == @ninf
      assert Math.divide(@ninf, -2) == @inf
    end

    test "infinity / 0 is infinity (sign-preserving)" do
      assert Math.divide(@inf, 0) == @inf
      assert Math.divide(@ninf, 0) == @ninf
    end

    test "infinity / infinity is NaN" do
      assert Math.divide(@inf, @inf) == @nan
      assert Math.divide(@ninf, @ninf) == @nan
    end

    test "NaN propagates" do
      assert Math.divide(@nan, 1) == @nan
      assert Math.divide(1, @nan) == @nan
    end
  end

  describe "modulo" do
    test "regular operands" do
      assert Math.modulo(10, 3) == 1
      assert_in_delta Math.modulo(10.5, 3), 1.5, 1.0e-9
    end

    test "modulo by float zero is NaN" do
      assert Math.modulo(5, 0.0) == @nan
    end

    test "modulo by integer zero returns sentinel" do
      assert Math.modulo(5, 0) == {:zero_division}
    end

    test "infinity in numerator is NaN" do
      assert Math.modulo(@inf, 2) == @nan
      assert Math.modulo(@ninf, 2) == @nan
    end

    test "finite mod infinity yields the value as a Float" do
      assert Math.modulo(10, @inf) === 10.0
      assert Math.modulo(-3, @inf) === -3.0
    end

    test "NaN propagates" do
      assert Math.modulo(@nan, 1) == @nan
      assert Math.modulo(1, @nan) == @nan
    end
  end

  describe "negate / absolute" do
    test "negate flips sign on specials" do
      assert Math.negate(@inf) == @ninf
      assert Math.negate(@ninf) == @inf
      assert Math.negate(@nan) == @nan
      assert Math.negate(5) == -5
    end

    test "absolute" do
      assert Math.absolute(@inf) == @inf
      assert Math.absolute(@ninf) == @inf
      assert Math.absolute(@nan) == @nan
      assert Math.absolute(-5) == 5
    end
  end

  describe "compare" do
    test "regular numbers" do
      assert Math.compare(1, 2) == :lt
      assert Math.compare(2, 1) == :gt
      assert Math.compare(1, 1) == :eq
    end

    test "infinity is greater than any finite number" do
      assert Math.compare(@inf, 1_000_000) == :gt
      assert Math.compare(1_000_000, @inf) == :lt
      assert Math.compare(@ninf, -1_000_000) == :lt
      assert Math.compare(-1_000_000, @ninf) == :gt
    end

    test "infinity equals itself" do
      assert Math.compare(@inf, @inf) == :eq
      assert Math.compare(@ninf, @ninf) == :eq
    end

    test "infinity is greater than -infinity" do
      assert Math.compare(@inf, @ninf) == :gt
      assert Math.compare(@ninf, @inf) == :lt
    end

    test "any comparison involving NaN is unordered" do
      assert Math.compare(@nan, 1) == :nan
      assert Math.compare(1, @nan) == :nan
      assert Math.compare(@nan, @nan) == :nan
      assert Math.compare(@nan, @inf) == :nan
    end
  end

  describe "apply_op (Liquid comparison operators)" do
    test "ordered (eq/lt/gt) maps the way Kernel does" do
      assert Math.apply_op(:==, @inf, @inf) == true
      assert Math.apply_op(:!=, @inf, @inf) == false
      assert Math.apply_op(:<=, @inf, @inf) == true
      assert Math.apply_op(:>=, @inf, @inf) == true
      assert Math.apply_op(:<, @inf, @inf) == false
      assert Math.apply_op(:>, @inf, @inf) == false

      assert Math.apply_op(:>, @inf, 100) == true
      assert Math.apply_op(:<, @inf, 100) == false
    end

    test "NaN: != is true, everything else is false" do
      for op <- [:==, :<, :>, :<=, :>=] do
        refute Math.apply_op(op, @nan, @nan), "#{op} with NaN==NaN should be false"
        refute Math.apply_op(op, @nan, 1), "#{op} with NaN==1 should be false"
        refute Math.apply_op(op, 1, @nan), "#{op} with 1==NaN should be false"
      end

      assert Math.apply_op(:!=, @nan, @nan) == true
      assert Math.apply_op(:!=, @nan, 1) == true
    end
  end

  describe "computation_error formatting" do
    test "Infinity / -Infinity / NaN" do
      assert Math.computation_error(@inf) ==
               "Liquid error: Computation results in 'Infinity'"

      assert Math.computation_error(@ninf) ==
               "Liquid error: Computation results in '-Infinity'"

      assert Math.computation_error(@nan) ==
               "Liquid error: Computation results in 'NaN' (Not a Number)"
    end
  end

  describe "filter integration (byte-match against Liquid gem)" do
    test "divided_by 0.0 produces signed infinity / NaN" do
      assert render("{{ 5 | divided_by: 0.0 }}") == "Infinity"
      assert render("{{ -5 | divided_by: 0.0 }}") == "-Infinity"
      assert render("{{ 0 | divided_by: 0.0 }}") == "NaN"
      assert render("{{ 0.0 | divided_by: 0.0 }}") == "NaN"
    end

    test "divided_by integer 0 still uses the error string" do
      assert render("{{ 5 | divided_by: 0 }}") == "Liquid error: divided by 0"
    end

    test "plus / minus / times propagate through specials" do
      ctx = %{"i" => @inf, "ni" => @ninf, "n" => @nan}
      assert render("{{ i | plus: 1 }}", ctx) == "Infinity"
      assert render("{{ i | plus: i }}", ctx) == "Infinity"
      assert render("{{ i | plus: ni }}", ctx) == "NaN"
      assert render("{{ i | minus: 1 }}", ctx) == "Infinity"
      assert render("{{ i | minus: i }}", ctx) == "NaN"
      assert render("{{ i | times: 2 }}", ctx) == "Infinity"
      assert render("{{ i | times: 0 }}", ctx) == "NaN"
      assert render("{{ i | times: -1 }}", ctx) == "-Infinity"
      assert render("{{ n | plus: 1 }}", ctx) == "NaN"
    end

    test "divided_by and modulo with specials" do
      ctx = %{"i" => @inf}
      assert render("{{ i | divided_by: 2 }}", ctx) == "Infinity"
      assert render("{{ i | divided_by: 0.0 }}", ctx) == "Infinity"
      assert render("{{ 1 | divided_by: i }}", ctx) == "0.0"
      assert render("{{ i | modulo: 2 }}", ctx) == "NaN"
      assert render("{{ 10 | modulo: i }}", ctx) == "10.0"
    end

    test "abs handles specials" do
      ctx = %{"i" => @inf, "ni" => @ninf, "n" => @nan}
      assert render("{{ i | abs }}", ctx) == "Infinity"
      assert render("{{ ni | abs }}", ctx) == "Infinity"
      assert render("{{ n | abs }}", ctx) == "NaN"
    end

    test "floor/ceil/round emit Liquid's computation-error string" do
      ctx = %{"i" => @inf, "n" => @nan}
      assert render("{{ i | floor }}", ctx) == "Liquid error: Computation results in 'Infinity'"
      assert render("{{ i | ceil }}", ctx) == "Liquid error: Computation results in 'Infinity'"
      assert render("{{ i | round }}", ctx) == "Liquid error: Computation results in 'Infinity'"

      assert render("{{ n | floor }}", ctx) ==
               "Liquid error: Computation results in 'NaN' (Not a Number)"
    end

    test "at_least / at_most pick the side Liquid would" do
      ctx = %{"i" => @inf, "n" => @nan}
      assert render("{{ 5 | at_least: i }}", ctx) == "Infinity"
      assert render("{{ 5 | at_most: i }}", ctx) == "5"
      assert render("{{ 5 | at_least: n }}", ctx) == "5"
    end

    test "comparisons in if/unless work with specials" do
      ctx = %{"i" => @inf, "ni" => @ninf, "n" => @nan}
      assert render("{% if i > 100 %}T{% else %}F{% endif %}", ctx) == "T"
      assert render("{% if i < 100 %}T{% else %}F{% endif %}", ctx) == "F"
      assert render("{% if i == i %}T{% else %}F{% endif %}", ctx) == "T"
      assert render("{% if i > ni %}T{% else %}F{% endif %}", ctx) == "T"
      assert render("{% if n != n %}T{% else %}F{% endif %}", ctx) == "T"
      assert render("{% if n == n %}T{% else %}F{% endif %}", ctx) == "F"
      assert render("{% if n < 1 %}T{% else %}F{% endif %}", ctx) == "F"
      assert render("{% if n > 1 %}T{% else %}F{% endif %}", ctx) == "F"
    end

    test "specials are truthy in if-tests" do
      ctx = %{"i" => @inf, "n" => @nan}
      assert render("{% if i %}T{% else %}F{% endif %}", ctx) == "T"
      assert render("{% if n %}T{% else %}F{% endif %}", ctx) == "T"
    end

    test "sum propagates infinity from array elements" do
      ctx = %{"arr" => [@inf, 1]}
      assert render("{{ arr | sum }}", ctx) == "Infinity"
    end

    test "filter chains preserve special values" do
      assert render("{{ 5 | divided_by: 0.0 | plus: 1 }}") == "Infinity"
      assert render("{{ 5 | divided_by: 0.0 | times: -1 }}") == "-Infinity"
      assert render("{{ 5 | divided_by: 0.0 | minus: \"5\" | divided_by: 0.0 | minus: \"5\" }}") ==
               "Infinity"
    end
  end

  defp render(template, ctx \\ %{}) do
    {:ok, parsed} = Liquex.parse(template)
    {result, _} = Liquex.render!(parsed, Liquex.Context.new(ctx))
    to_string(result)
  end
end
