defmodule Liquex.Cache.SimpleCacheTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Liquex.Cache.SimpleCache

  setup do
    SimpleCache.init()
  end

  describe "fetch" do
    test "calls function once" do
      SimpleCache.fetch(:test, fn -> send(self(), :called1) end)
      SimpleCache.fetch(:test, fn -> send(self(), :called2) end)

      assert_received :called1
      refute_received :called2
    end
  end
end
