defmodule Liquex.ErrorModeRenderTest do
  use ExUnit.Case, async: true

  alias Liquex.Context

  describe "filter errors honor :error_mode" do
    setup do
      {:ok, ast} = Liquex.parse("{{ x | nope_filter }}")
      %{ast: ast}
    end

    test ":lax silently swallows the filter error", %{ast: ast} do
      ctx = Context.new(%{"x" => "hi"}, error_mode: :lax)
      {result, ctx} = Liquex.render!(ast, ctx)

      assert IO.iodata_to_binary(result) == "hi"
      assert ctx.errors == []
    end

    test ":warn collects the error in context.errors", %{ast: ast} do
      ctx = Context.new(%{"x" => "hi"}, error_mode: :warn)
      {result, ctx} = Liquex.render!(ast, ctx)

      assert IO.iodata_to_binary(result) == "hi"
      assert [%Liquex.Error{message: msg}] = ctx.errors
      assert msg =~ "Invalid filter nope_filter"
    end

    test ":strict raises Liquex.Error", %{ast: ast} do
      ctx = Context.new(%{"x" => "hi"}, error_mode: :strict)

      assert_raise Liquex.Error, ~r/Invalid filter nope_filter/, fn ->
        Liquex.render!(ast, ctx)
      end
    end
  end

  describe "filter typo suggestions" do
    test "close typo includes did-you-mean hint" do
      {:ok, ast} = Liquex.parse("{{ x | upcas }}")
      {_r, ctx} = Liquex.render!(ast, Context.new(%{"x" => "hi"}, error_mode: :warn))
      assert [%Liquex.Error{message: msg}] = ctx.errors
      assert msg =~ "Invalid filter upcas"
      assert msg =~ "did you mean `upcase`?"
    end

    test "totally unrelated name has no hint" do
      {:ok, ast} = Liquex.parse("{{ x | qqxyzzy }}")
      {_r, ctx} = Liquex.render!(ast, Context.new(%{"x" => "hi"}, error_mode: :warn))
      assert [%Liquex.Error{message: msg}] = ctx.errors
      assert msg =~ "Invalid filter qqxyzzy"
      refute msg =~ "did you mean"
    end
  end

  describe "stray break/continue honors :error_mode" do
    test ":lax swallows stray break (default)" do
      {:ok, ast} = Liquex.parse("hello{% break %}world")
      {_result, ctx} = Liquex.render!(ast, Context.new(%{}))
      assert ctx.errors == []
    end

    test ":warn collects stray break" do
      {:ok, ast} = Liquex.parse("hello{% break %}world")
      {_result, ctx} = Liquex.render!(ast, Context.new(%{}, error_mode: :warn))
      assert [%Liquex.Error{message: msg}] = ctx.errors
      assert msg =~ "'break' found outside"
    end

    test ":strict raises on stray continue" do
      {:ok, ast} = Liquex.parse("hello{% continue %}world")

      assert_raise Liquex.Error, ~r/'continue' found outside/, fn ->
        Liquex.render!(ast, Context.new(%{}, error_mode: :strict))
      end
    end
  end

  describe "Context.new/2 default" do
    test "defaults to :lax" do
      ctx = Context.new(%{})
      assert ctx.error_mode == :lax
    end
  end
end
