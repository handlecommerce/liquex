defmodule Liquex.Drop.RangeTest do
  @moduledoc false

  use ExUnit.Case, async: true

  defp render(template, env \\ %{}) do
    ctx = Liquex.Context.new(env)
    {:ok, ast} = Liquex.parse(template)
    {output, _} = Liquex.render!(ast, ctx)
    IO.iodata_to_binary(output)
  end

  describe "Range drop attributes" do
    test "first / last on an assigned range" do
      assert render("{% assign r = (1..5) %}{{ r.first }}-{{ r.last }}") == "1-5"
    end

    test "size on an assigned range" do
      assert render("{% assign r = (1..5) %}{{ r.size }}") == "5"
    end

    test "size on a stepped range passed via the context" do
      assert render("{{ r.size }}", %{"r" => 1..10//2}) == "5"
    end

    test "native struct fields still work" do
      assert render("{{ r.step }}", %{"r" => 3..7}) == "1"
    end

    test "unknown keys render empty" do
      assert render("[{% assign r = (1..5) %}{{ r.nope }}]") == "[]"
    end
  end
end
