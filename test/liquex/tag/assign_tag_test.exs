defmodule Liquex.Tag.AssignTagTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  alias Liquex.Context

  describe "parse" do
    test "parse simple assign" do
      "{% assign a = 5 %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.AssignTag},
          [left: "a", right: [literal: 5, filters: []]]
        }
      ])
    end

    test "parse field assign" do
      "{% assign a = b %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.AssignTag},
          [left: "a", right: [field: [key: "b"], filters: []]]
        }
      ])
    end

    test "parse field assign with filter" do
      "{% assign a = b | divided_by: 4 %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.AssignTag},
          [
            left: "a",
            right: [field: [key: "b"], filters: [filter: ["divided_by", arguments: [literal: 4]]]]
          ]
        }
      ])
    end
  end

  describe "render" do
    test "assign simple value" do
      context = Context.new(%{})

      {:ok, template} =
        """
        {% assign a = "Hello World!" %}
        {{ a }}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, context)
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello World!"
    end

    test "assign another field" do
      context = Context.new(%{"a" => %{"b" => "Hello World!"}})

      {:ok, template} =
        """
        {% assign c = a.b %}
        {{ c }}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, context)
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello World!"
    end

    test "assign another field with filter" do
      context = Context.new(%{"a" => %{"b" => 10}})

      {:ok, template} =
        """
        {% assign c = a.b | divided_by: 2 %}
        {{ c }}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, context)
             |> elem(0)
             |> to_string()
             |> String.trim() == "5"
    end
  end

  describe "render with liquid tag" do
    test "assign simple value" do
      context = Context.new(%{})

      {:ok, template} =
        """
        {% liquid assign a = "Hello World!" %}
        {{ a }}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, context)
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello World!"
    end

    test "assign another field" do
      context = Context.new(%{"a" => %{"b" => "Hello World!"}})

      {:ok, template} =
        """
        {% liquid assign c = a.b %}
        {{ c }}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, context)
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello World!"
    end

    test "assign another field with filter" do
      context = Context.new(%{"a" => %{"b" => 10}})

      {:ok, template} =
        """
        {% liquid assign b = a.b
         assign c = a.b | divided_by: 2 %}
        {{ c }}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, context)
             |> elem(0)
             |> to_string()
             |> String.trim() == "5"
    end
  end
end
