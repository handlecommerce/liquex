defmodule Liquex.FilterTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Liquex.Filter
  doctest Liquex.Filter

  test "apply" do
    assert 5 == Filter.apply(-5, {:filter, ["abs", {:arguments, []}]}, %{})
  end

  test "date" do
    assert "2022" ==
             Filter.apply(
               ~D[2022-01-01],
               {:filter, ["date", {:arguments, [{:literal, "%Y"}]}]},
               %{}
             )

    assert nil ==
             Filter.apply(
               nil,
               {:filter, ["date", {:arguments, [{:literal, "%Y"}]}]},
               %{}
             )
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
    test "sums numeric items" do
      assert Filter.sum([1, 2, 3], %{}) == 6
      assert Filter.sum([1.5, 2.5], %{}) == 4.0
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
end
