defmodule Liquex.CacheTest do
  @moduledoc false

  # SimpleCache uses a singleton :named_table; serialize tests that touch it.
  use ExUnit.Case, async: false

  alias Liquex.Cache
  alias Liquex.Cache.DisabledCache
  alias Liquex.Cache.SimpleCache
  alias Liquex.Context

  defmodule CountingFilter do
    @moduledoc false
    use Liquex.Filter

    def expensive(value, context) do
      Cache.memoize(context, {:expensive, value}, fn ->
        :ets.update_counter(:liquex_cache_test_counter, :calls, 1)
        String.upcase(to_string(value))
      end)
    end
  end

  describe "memoize/3" do
    setup do
      SimpleCache.init()
      :ok
    end

    test "calls function once with SimpleCache" do
      ctx = Context.new(%{}, cache: SimpleCache)

      Cache.memoize(ctx, :k, fn -> send(self(), :first) end)
      Cache.memoize(ctx, :k, fn -> send(self(), :second) end)

      assert_received :first
      refute_received :second
    end

    test "calls function every time with default DisabledCache" do
      ctx = Context.new(%{})
      assert ctx.cache == DisabledCache

      Cache.memoize(ctx, :k, fn -> send(self(), :first) end)
      Cache.memoize(ctx, :k, fn -> send(self(), :second) end)

      assert_received :first
      assert_received :second
    end

    test "cache_prefix isolates contexts sharing one cache" do
      a = Context.new(%{}, cache: SimpleCache, cache_prefix: "a")
      b = Context.new(%{}, cache: SimpleCache, cache_prefix: "b")

      assert :from_a == Cache.memoize(a, :same_key, fn -> :from_a end)
      assert :from_b == Cache.memoize(b, :same_key, fn -> :from_b end)
      # Re-fetch under prefix "a" still returns the original cached value.
      assert :from_a == Cache.memoize(a, :same_key, fn -> :should_not_run end)
    end

    test "filter using memoize/3 runs once across repeated references" do
      :ets.new(:liquex_cache_test_counter, [:named_table, :public, :set])
      :ets.insert(:liquex_cache_test_counter, {:calls, 0})

      ctx =
        Context.new(%{},
          cache: SimpleCache,
          filter_module: CountingFilter
        )

      template = "{{ 'foo' | expensive }}-{{ 'foo' | expensive }}-{{ 'bar' | expensive }}"
      {:ok, ast} = Liquex.parse(template)
      {output, _} = Liquex.render!(ast, ctx)

      assert IO.iodata_to_binary(output) == "FOO-FOO-BAR"
      # 'foo' computed once + 'bar' computed once = 2 calls, not 3.
      assert :ets.lookup_element(:liquex_cache_test_counter, :calls, 2) == 2
    after
      if :ets.whereis(:liquex_cache_test_counter) != :undefined do
        :ets.delete(:liquex_cache_test_counter)
      end
    end
  end
end
