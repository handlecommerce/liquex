defmodule Liquex.DynamicResolverTest do
  @moduledoc false
  use ExUnit.Case, async: true

  describe "dynamic resolver" do
    test "calls dynamic resolver correctly" do
      resolver = fn _, _ctx, param ->
        param
      end

      {:ok, template_ast} = Liquex.parse("Hello {{ name['John'] }} {{ name.Smith }}")

      {content, _context} =
        Liquex.render!(
          template_ast,
          Liquex.Context.new(%{
            "name" => resolver
          })
        )

      assert Enum.join(content, "") == "Hello John Smith"
    end

    test "calls dynamic resolver correctly with a referenced variable" do
      resolver = fn _, _ctx, param ->
        param
      end

      {:ok, template_ast} = Liquex.parse("Hello {{ name[a] }}")

      {content, _context} =
        Liquex.render!(
          template_ast,
          Liquex.Context.new(%{
            "a" => "John",
            "name" => resolver
          })
        )

      assert Enum.join(content, "") == "Hello John"
    end
  end
end
