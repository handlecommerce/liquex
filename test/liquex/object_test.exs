defmodule Liquex.ObjectTest do
  use ExUnit.Case, async: true

  alias Liquex.Object
  alias Liquex.Parser

  describe "render" do
    test "simple objects" do
      assert "5" == render("{{ 5 }}")
      assert "Hello" == render("{{ 'Hello' }}")
      assert "true" == render("{{ true }}")
      assert "" == render("{{ nil }}")
    end

    test "simple fields" do
      context = %{
        "a" => "hello",
        "b" => %{"c" => 1}
      }

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

  def render(doc, context \\ %{}) do
    with {:ok, parsed_doc, _, _, _, _} <- Parser.parse(doc),
         [object: object] <- parsed_doc do
      Object.render(object, context)
    end
  end
end
