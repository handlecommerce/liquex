defmodule Liquex.FilterTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Liquex.Filter
  doctest Liquex.Filter

  test "apply" do
    assert {5, _} = Filter.apply(-5, {:filter, ["abs", {:arguments, []}]}, %{})
  end

  test "date" do
    assert {"2022", _} =
             Filter.apply(
               ~D[2022-01-01],
               {:filter, ["date", {:arguments, [{:literal, "%Y"}]}]},
               %{}
             )

    assert {nil, _} =
             Filter.apply(
               nil,
               {:filter, ["date", {:arguments, [{:literal, "%Y"}]}]},
               %{}
             )
  end

  describe "date with timezone context" do
    defp render!(template, ctx) do
      {:ok, ast} = Liquex.parse(template)
      {data, _} = Liquex.render!(ast, ctx)
      to_string(data)
    end

    test "Etc/UTC override forces zero offset" do
      ctx = Liquex.Context.new(%{}, timezone: "Etc/UTC")
      assert render!("{{ 'now' | date: '%z' }}", ctx) == "+0000"
    end

    test "named zone shifts the wall clock and offset" do
      ctx = Liquex.Context.new(%{}, timezone: "America/New_York")
      # 2023-11-14 22:13:20 UTC -> 17:13:20-05:00
      assert render!("{{ 1700000000 | date: '%Y-%m-%d %H:%M:%S %z' }}", ctx) ==
               "2023-11-14 17:13:20 -0500"
    end

    test "named zone applies to 'now'" do
      ctx = Liquex.Context.new(%{}, timezone: "Asia/Tokyo")
      assert render!("{{ 'now' | date: '%z' }}", ctx) == "+0900"
    end

    test "missing zone gives a clear Liquex error, not a vague filter error" do
      ctx = Liquex.Context.new(%{}, timezone: "Mars/Olympus_Mons")

      assert_raise Liquex.Error, ~r/Cannot resolve timezone/, fn ->
        render!("{{ 'now' | date: '%z' }}", ctx)
      end
    end

    test "default (no :timezone option) renders in host-local time" do
      ctx = Liquex.Context.new(%{})
      # Whatever the host TZ is, the offset matches the host's libc localtime.
      assert render!("{{ 1700000000 | date: '%z' }}", ctx) ==
               format_offset_at_unix(1_700_000_000)
    end

    defp format_offset_at_unix(unix) do
      utc_erl = DateTime.from_unix!(unix) |> DateTime.to_naive() |> NaiveDateTime.to_erl()
      local_erl = :calendar.universal_time_to_local_time(utc_erl)

      offset =
        :calendar.datetime_to_gregorian_seconds(local_erl) -
          :calendar.datetime_to_gregorian_seconds(utc_erl)

      sign = if offset < 0, do: "-", else: "+"
      abs = abs(offset)
      hours = div(abs, 3600) |> Integer.to_string() |> String.pad_leading(2, "0")
      mins = rem(abs, 3600) |> div(60) |> Integer.to_string() |> String.pad_leading(2, "0")
      sign <> hours <> mins
    end
  end

  describe "base64" do
    test "encode and decode round-trip" do
      assert Filter.base64_encode("_hello_", %{}) == "X2hlbGxvXw=="
      assert Filter.base64_decode("X2hlbGxvXw==", %{}) == "_hello_"
    end

    test "url-safe encode and decode round-trip" do
      assert Filter.base64_url_safe_encode("_hello world?+/", %{}) == "X2hlbGxvIHdvcmxkPysv"
      assert Filter.base64_url_safe_decode("X2hlbGxvIHdvcmxkPysv", %{}) == "_hello world?+/"
    end

    test "decode raises on invalid input" do
      assert_raise Liquex.Error, ~r/invalid base64/, fn ->
        Filter.base64_decode("not!valid", %{})
      end

      assert_raise Liquex.Error, ~r/invalid base64/, fn ->
        Filter.base64_url_safe_decode("not!valid", %{})
      end
    end
  end

  describe "replace_last / remove_last" do
    test "replaces the final occurrence only" do
      assert Filter.replace_last("red, red, red", "red", "blue", %{}) == "red, red, blue"
    end

    test "returns input unchanged when not found" do
      assert Filter.replace_last("abc", "x", "y", %{}) == "abc"
    end

    test "remove_last is replace_last with empty replacement" do
      assert Filter.remove_last("red, red, red", "red", %{}) == "red, red, "
    end
  end

  describe "find / find_index / has / reject" do
    @items [%{"v" => 1, "name" => "a"}, %{"v" => 2, "name" => "b"}, %{"v" => 3, "name" => "c"}]

    test "find with target value returns the matching item" do
      assert Filter.find(@items, "v", 2, %{}) == %{"v" => 2, "name" => "b"}
    end

    test "find without target returns the first item with truthy property" do
      items = [%{"v" => nil}, %{"v" => false}, %{"v" => "yes"}]
      assert Filter.find(items, "v", %{}) == %{"v" => "yes"}
    end

    test "find returns nil for empty array or no match" do
      assert Filter.find([], "v", 2, %{}) == nil
      assert Filter.find(@items, "v", 99, %{}) == nil
    end

    test "find_index with target value returns the matching index" do
      assert Filter.find_index(@items, "v", 2, %{}) == 1
    end

    test "find_index returns nil for empty array or no match" do
      assert Filter.find_index([], "v", 2, %{}) == nil
      assert Filter.find_index(@items, "v", 99, %{}) == nil
    end

    test "has returns true when an item matches" do
      assert Filter.has(@items, "v", 2, %{}) == true
      assert Filter.has(@items, "v", 99, %{}) == false
    end

    test "has returns false on empty array" do
      assert Filter.has([], "v", 2, %{}) == false
    end

    test "reject removes matching items by target value" do
      assert Filter.reject(@items, "v", 2, %{}) == [
               %{"v" => 1, "name" => "a"},
               %{"v" => 3, "name" => "c"}
             ]
    end

    test "reject with property removes items with truthy property" do
      items = [%{"a" => true}, %{"a" => false}, %{"a" => nil}]
      assert Filter.reject(items, "a", %{}) == [%{"a" => false}, %{"a" => nil}]
    end
  end

  describe "sum" do
    test "sums integer items" do
      assert Filter.sum([1, 2, 3], %{}) == 6
    end

    test "sums float items via Decimal precision" do
      assert Decimal.equal?(Filter.sum([1.5, 2.5], %{}), Decimal.new("4.0"))
      assert Decimal.equal?(Filter.sum([0.1, 0.2], %{}), Decimal.new("0.3"))
    end

    test "sums by property" do
      assert Filter.sum([%{"v" => 1}, %{"v" => 2}, %{"v" => 3}], "v", %{}) == 6
    end

    test "returns 0 on empty list" do
      assert Filter.sum([], %{}) == 0
      assert Filter.sum([], "v", %{}) == 0
    end

    test "non-numeric items coerce to 0" do
      assert Filter.sum(["a", "b", 1], %{}) == 1
    end
  end

  describe "decimal-precision arithmetic" do
    # Liquid wraps native floats in BigDecimal for arithmetic, then converts the
    # result back to Float for rendering. Liquex mirrors that with the Decimal
    # library so `9.99 + 14.5` renders as `"24.49"` rather than the IEEE-noise
    # `"24.490000000000002"` that raw Float arithmetic would produce.
    defp render(template, ctx \\ %{}) do
      {:ok, parsed} = Liquex.parse(template)
      {result, _} = Liquex.render!(parsed, Liquex.Context.new(ctx))
      to_string(result)
    end

    test "plus / minus / times / divided_by render Liquid's clean form" do
      assert render("{{ 9.99 | plus: 14.5 }}") == "24.49"
      assert render("{{ 0.1 | plus: 0.2 }}") == "0.3"
      assert render("{{ 5 | minus: 0.5 }}") == "4.5"
      assert render("{{ 100 | times: 3.5 }}") == "350.0"
      assert render("{{ 9.99 | times: 2 }}") == "19.98"
    end

    test "integer/integer division floors (Ruby-style)" do
      assert render("{{ 7 | divided_by: 4 }}") == "1"
      assert render("{{ -7 | divided_by: 4 }}") == "-2"
      assert render("{{ 7 | divided_by: -4 }}") == "-2"
    end

    test "any-float division renders with shortest-round-trip precision" do
      # 16-digit precision matches Liquid's BigDecimal -> Float -> Float#to_s.
      assert render("{{ 1 | divided_by: 3.0 }}") == "0.3333333333333333"
      assert render("{{ 1.0 | divided_by: 3 }}") == "0.3333333333333333"
    end

    test "modulo handles floats and Ruby-style negative wrapping" do
      assert render("{{ 10.5 | modulo: 3 }}") == "1.5"
      assert render("{{ 10 | modulo: -3 }}") == "-2"
      assert render("{{ -10 | modulo: 3 }}") == "2"
    end

    test "filter chains preserve Decimal precision" do
      assert render("{{ 9.99 | times: 2 | plus: 0.02 }}") == "20.0"
      assert render("{{ 1.5 | plus: 0.5 | times: 4 }}") == "8.0"
    end

    test "string operands coerce via Liquid's int/float dispatch" do
      assert render(~s({{ "9.99" | plus: 14.5 }})) == "24.49"
      assert render(~s({{ "5.5" | plus: 3 }})) == "8.5"
      assert render(~s({{ "5" | plus: 3 }})) == "8"
    end

    test "Filter.plus returns Decimal when any operand is non-integer" do
      assert Decimal.equal?(Filter.plus(9.99, 14.5, %{}), Decimal.new("24.49"))
      assert Decimal.equal?(Filter.plus(5, 3.0, %{}), Decimal.new("8.0"))
      assert Filter.plus(5, 3, %{}) == 8
    end
  end
end
