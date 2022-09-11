defmodule Liquex.Cache.DisabledCacheTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Liquex.Cache.DisabledCache

  describe "fetch" do
    test "calls function every time" do
      DisabledCache.fetch(:test, fn -> send(self(), :called1) end)
      DisabledCache.fetch(:test, fn -> send(self(), :called2) end)

      assert_received :called1
      assert_received :called2
    end
  end
end
