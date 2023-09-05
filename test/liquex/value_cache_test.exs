defmodule Liquex.ValueCacheTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Liquex.ValueCache

  describe "value cache" do
    test "calls resolver function once" do
      resolver = fn _, _ctx ->
        send(self(), :called)

        "John"
      end

      {:ok, template_ast} = Liquex.parse("Hello {{ name }} {{ name }}")

      {content, _context} =
        Liquex.render!(
          template_ast,
          Liquex.Context.new(%{
            "name" => resolver
          })
        )

      assert Enum.join(content, "") == "Hello John John"

      assert_received :called
      assert_received :called

      resolver_cached = fn _, ctx ->
        send(self(), :called_cached)

        ValueCache.return_cached_result(ctx, "John")
      end

      {content, _context} =
        Liquex.render!(
          template_ast,
          Liquex.Context.new(%{
            "name" => resolver_cached
          })
        )

      assert Enum.join(content, "") == "Hello John John"

      assert_received :called_cached
      refute_received :called_cached
    end

    test "calls resolver function once with nested resolver" do
      resolver_cached = fn _, ctx ->
        send(self(), :called_cached)

        ValueCache.return_cached_result(ctx, "John")
      end

      {:ok, template_ast} = Liquex.parse("Hello {{ customer.a.name }} {{ customer.a.name }}")

      {content, _context} =
        Liquex.render!(
          template_ast,
          Liquex.Context.new(%{
            "customer" => %{
              "a" => %{
                "name" => resolver_cached
              }
            }
          })
        )

      assert Enum.join(content, "") == "Hello John John"

      assert_received :called_cached
      refute_received :called_cached
    end

    test "calls resolver function once with nested resolver that returns another resolver" do
      pid = self()

      resolver_cached = fn _, ctx ->
        send(pid, :called_cached_top)

        ValueCache.return_cached_result(ctx, %{
          "name" => fn _, ctx ->
            send(pid, :called_cached_inner)

            ValueCache.return_cached_result(ctx, "John")
          end
        })
      end

      {:ok, template_ast} = Liquex.parse("Hello {{ customer.a.name }} {{ customer.a.name }}")

      {content, _context} =
        Liquex.render!(
          template_ast,
          Liquex.Context.new(%{
            "customer" => %{
              "a" => resolver_cached
            }
          })
        )

      assert Enum.join(content, "") == "Hello John John"

      assert_received :called_cached_top
      refute_received :called_cached_top

      assert_received :called_cached_inner
      refute_received :called_cached_inner
    end
  end

  describe "manual cache" do
    test "can access cache from within same context" do
      resolver = fn _, ctx ->
        cached = ValueCache.get_cached(ctx, "name")

        if cached do
          {cached, ctx}
        else
          send(self(), :called)
          {"John", ValueCache.cache(ctx, "name", "John")}
        end
      end

      {:ok, template_ast} = Liquex.parse("Hello {{ name }} {{ name }}")

      {content, _context} =
        Liquex.render!(
          template_ast,
          Liquex.Context.new(%{
            "name" => resolver
          })
        )

      assert Enum.join(content, "") == "Hello John John"

      assert_received :called
      refute_received :called
    end

    test "can access cache from within shared parent context" do
      first_resolver = fn _, ctx ->
        ValueCache.get_cached(ctx, "name", level: :parent)
        |> case do
          [first, _last] ->
            {first, ctx}

          nil ->
            send(self(), :called)
            name = ["John", "Smith"]
            {name |> Enum.at(0), ValueCache.cache(ctx, "name", name, level: :parent)}
        end
      end

      last_resolver = fn _, ctx ->
        ValueCache.get_cached(ctx, "name", level: :parent)
        |> case do
          [_first, last] ->
            {last, ctx}

          nil ->
            send(self(), :called)
            name = ["John", "Smith"]
            {name |> Enum.at(1), ValueCache.cache(ctx, "name", name, level: :parent)}
        end
      end

      {:ok, template_ast} = Liquex.parse("Hello {{ name.first }} {{ name.last }}")

      {content, _context} =
        Liquex.render!(
          template_ast,
          Liquex.Context.new(%{
            "name" => %{
              "first" => first_resolver,
              "last" => last_resolver
            }
          })
        )

      assert Enum.join(content, "") == "Hello John Smith"

      assert_received :called
      refute_received :called
    end

    test "can access cache from within a dynamic resolver" do
      resolver = fn _, ctx, param ->
        cached = ValueCache.get_cached(ctx, param)

        if cached do
          {cached, ctx}
        else
          send(self(), :called)
          {"John", ValueCache.cache(ctx, param, "John")}
        end
      end

      {:ok, template_ast} = Liquex.parse("Hello {{ name.a }} {{ name.a }}")

      {content, _context} =
        Liquex.render!(
          template_ast,
          Liquex.Context.new(%{
            "name" => resolver
          })
        )

      assert Enum.join(content, "") == "Hello John John"

      assert_received :called
      refute_received :called
    end
  end
end
