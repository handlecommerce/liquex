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

    test "removes tail whitespace" do
      assert "Hello" == render("{{ 'Hello' -}} ")
    end

    test "removes leading whitespace" do
      assert "Hello" == render(" {{- 'Hello' }}")
    end
  end

  describe "render with filter" do
    test "abs" do
      assert "5" == render("{{ -5 | abs }}")
      assert "5" == render("{{ -5 | abs | abs }}")
    end

    test "invalid filter" do
      assert "-5" == render("{{ -5 | bad_filter }}")
    end
  end

  describe "dynamic fields" do
    test "simple new field" do
      context = Context.new(%{"message" => fn _ -> "hello world" end})
      assert "hello world" == render("{{ message }}", context)
    end

    test "dynamic field on parent object" do
      context =
        Context.new(%{
          "message" => %{
            "value" => "Hello World",
            "calculated_value" => fn %{"value" => value} -> value end
          }
        })

      assert "Hello World" == render("{{ message.calculated_value }}", context)
    end
  end

  def render(doc, context \\ %Context{}) do
    {:ok, parsed_doc, _, _, _, _} = Parser.parse(doc)

    {result, _} = Liquex.render(parsed_doc, context)

    result |> to_string()
  end
end
