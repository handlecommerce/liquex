defmodule Liquex.Render.ObjectTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Liquex.Context
  alias Liquex.Parser

  describe "render" do
    test "simple objects" do
      assert "5" == render("{{ 5 }}")
      assert "Hello" == render("{{ 'Hello' }}")
      assert "true" == render("{{ true }}")
      assert "" == render("{{ nil }}")
    end

    test "simple fields" do
      context =
        Context.new(%{
          "a" => "hello",
          "b" => %{"c" => 1}
        })

      assert "hello" == render("{{ a }}", context)
      assert "1" == render("{{ b.c }}", context)
    end
  end

  describe "render with filter" do
    test "abs" do
      assert "5" == render("{{ -5 | abs }}")
      assert "5" == render("{{ -5 | abs | abs }}")
    end
  end

  def render(doc, context \\ %Context{}) do
    {:ok, parsed_doc, _, _, _, _} = Parser.parse(doc)

    {[result], _} = Liquex.render(parsed_doc, context)

    result
  end
end
