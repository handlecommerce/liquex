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

  describe "Context.new/2" do
    test "defaults to :lax" do
      ctx = Context.new(%{})
      assert ctx.error_mode == :lax
    end

    test "honors :strict and :warn" do
      assert Context.new(%{}, error_mode: :strict).error_mode == :strict
      assert Context.new(%{}, error_mode: :warn).error_mode == :warn
    end
  end

  describe "Context.new_isolated_subscope/2" do
    test "propagates error_mode to sub-scope (e.g. {% render %} partials)" do
      parent = Context.new(%{}, error_mode: :strict)
      sub = Context.new_isolated_subscope(parent)
      assert sub.error_mode == :strict
    end
  end

  describe "Context.report_error/2" do
    test ":strict raises the error directly" do
      err = Liquex.Error.render_error("boom")
      ctx = Context.new(%{}, error_mode: :strict)

      assert_raise Liquex.Error, "boom", fn ->
        Context.report_error(ctx, err)
      end
    end

    test ":warn prepends the error to context.errors" do
      err = Liquex.Error.render_error("boom")
      ctx = Context.new(%{}, error_mode: :warn)

      result = Context.report_error(ctx, err)
      assert [^err] = result.errors
    end

    test ":lax returns the context unchanged" do
      err = Liquex.Error.render_error("boom")
      ctx = Context.new(%{}, error_mode: :lax)

      assert Context.report_error(ctx, err) == ctx
    end
  end

  describe "Liquex.Filter.filter_names/1 and did_you_mean/2" do
    test "filter_names exposes built-in filter names but excludes framework helpers" do
      names = Liquex.Filter.filter_names(Liquex.Filter)

      assert "upcase" in names
      assert "replace" in names
      refute "apply" in names
      refute "filter_name" in names
    end

    test "did_you_mean returns a hint for close matches" do
      assert Liquex.Filter.did_you_mean("upcas", Liquex.Filter) == " (did you mean `upcase`?)"
      assert Liquex.Filter.did_you_mean("repalce", Liquex.Filter) =~ "did you mean `replace`?"
    end

    test "did_you_mean returns empty string when no close match exists" do
      assert Liquex.Filter.did_you_mean("qqxyzzy_foo", Liquex.Filter) == ""
    end
  end

  describe "filter typo suggestions consult the custom filter_module" do
    defmodule CustomFilter do
      use Liquex.Filter
      def shoutify(value, _ctx), do: String.upcase(to_string(value)) <> "!!!"
    end

    test "suggests filters from the user's custom module" do
      {:ok, ast} = Liquex.parse("{{ x | shoutfy }}")

      ctx =
        Context.new(%{"x" => "hi"}, error_mode: :warn, filter_module: CustomFilter)

      {_r, ctx} = Liquex.render!(ast, ctx)
      assert [%Liquex.Error{message: msg}] = ctx.errors
      assert msg =~ "did you mean `shoutify`?"
    end
  end
end
