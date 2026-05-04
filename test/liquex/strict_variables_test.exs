defmodule Liquex.StrictVariablesTest do
  use ExUnit.Case, async: true

  alias Liquex.Context

  defp render(template, ctx) do
    {:ok, ast} = Liquex.parse(template)
    Liquex.render!(ast, ctx)
  end

  describe ":strict_variables off (default) — undefined renders as empty" do
    test "missing top-level variable renders as empty without errors" do
      ctx = Context.new(%{})
      {result, ctx} = render("[{{ missing }}]", ctx)
      assert IO.iodata_to_binary(result) == "[]"
      assert ctx.errors == []
    end

    test "missing nested key on a defined parent renders as empty" do
      ctx = Context.new(%{"x" => %{"y" => 1}})
      {result, ctx} = render("[{{ x.missing }}]", ctx)
      assert IO.iodata_to_binary(result) == "[]"
      assert ctx.errors == []
    end
  end

  describe ":strict_variables on with :error_mode :lax — silent" do
    test "undefined variable still renders empty without raising" do
      ctx = Context.new(%{}, strict_variables: true, error_mode: :lax)
      {result, ctx} = render("[{{ missing }}]", ctx)
      assert IO.iodata_to_binary(result) == "[]"
      # :lax swallows the error even when strict_variables is on.
      assert ctx.errors == []
    end
  end

  describe ":strict_variables on with :error_mode :warn — collects" do
    test "undefined variable accumulates a Liquex.Error" do
      ctx = Context.new(%{}, strict_variables: true, error_mode: :warn)
      {result, ctx} = render("[{{ missing }}]", ctx)
      assert IO.iodata_to_binary(result) == "[]"
      assert [%Liquex.Error{message: msg}] = ctx.errors
      assert msg =~ "Undefined variable: missing"
    end

    test "nested missing key reports the missing leaf" do
      ctx = Context.new(%{"x" => %{}}, strict_variables: true, error_mode: :warn)
      {_r, ctx} = render("{{ x.missing }}", ctx)
      assert [%Liquex.Error{message: msg}] = ctx.errors
      assert msg =~ "Undefined variable: missing"
    end

    test "defined nil values are NOT reported" do
      # x is defined as nil — that's a real value, not a missing variable.
      ctx = Context.new(%{"x" => nil}, strict_variables: true, error_mode: :warn)
      {_r, ctx} = render("{{ x }}", ctx)
      assert ctx.errors == []
    end

    test "defined values aren't reported" do
      ctx = Context.new(%{"x" => "hi"}, strict_variables: true, error_mode: :warn)
      {result, ctx} = render("{{ x }}", ctx)
      assert IO.iodata_to_binary(result) == "hi"
      assert ctx.errors == []
    end
  end

  describe ":strict_variables on with :error_mode :strict — raises" do
    test "undefined top-level variable raises Liquex.Error" do
      ctx = Context.new(%{}, strict_variables: true, error_mode: :strict)

      assert_raise Liquex.Error, ~r/Undefined variable: missing/, fn ->
        render("{{ missing }}", ctx)
      end
    end

    test "undefined nested key raises Liquex.Error" do
      ctx = Context.new(%{"x" => %{}}, strict_variables: true, error_mode: :strict)

      assert_raise Liquex.Error, ~r/Undefined variable: missing/, fn ->
        render("{{ x.missing }}", ctx)
      end
    end
  end

  describe "interactions" do
    test "filter argument referencing undefined variable also reports" do
      ctx = Context.new(%{}, strict_variables: true, error_mode: :warn)
      {_r, ctx} = render("{{ 'hi' | append: missing }}", ctx)
      assert [%Liquex.Error{message: msg}] = ctx.errors
      assert msg =~ "Undefined variable: missing"
    end

    test "for loop over undefined collection reports once" do
      ctx = Context.new(%{}, strict_variables: true, error_mode: :warn)
      {_r, ctx} = render("{% for i in missing %}{{ i }}{% endfor %}", ctx)
      assert [%Liquex.Error{message: msg}] = ctx.errors
      assert msg =~ "Undefined variable: missing"
    end

    test "Context.new_isolated_subscope propagates strict_variables" do
      parent = Context.new(%{}, strict_variables: true)
      sub = Context.new_isolated_subscope(parent)
      assert sub.strict_variables == true
    end
  end

  describe "Context defaults" do
    test "strict_variables defaults to false" do
      ctx = Context.new(%{})
      assert ctx.strict_variables == false
    end

    test "explicit value is respected" do
      assert Context.new(%{}, strict_variables: true).strict_variables == true
    end
  end
end
