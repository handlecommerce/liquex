defmodule Liquex.Tag.ForTagTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  alias Liquex.Context

  describe "parse" do
    test "parse for block with field" do
      "{% for i in x %}Hello{% endfor %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.ForTag},
          identifier: "i",
          collection: [field: [key: "x"]],
          parameters: [],
          contents: [text: "Hello"]
        }
      ])
    end

    test "parse for block with else" do
      "{% for i in x %}Hello{% else %}Goodbye{% endfor %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.ForTag},
          identifier: "i",
          collection: [field: [key: "x"]],
          parameters: [],
          contents: [text: "Hello"],
          else: [contents: [text: "Goodbye"]]
        }
      ])
    end

    test "parse for block with range" do
      "{% for i in (1..5) %}Hello{% endfor %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.ForTag},
          identifier: "i",
          collection: [inclusive_range: [begin: [literal: 1], end: [literal: 5]]],
          parameters: [],
          contents: [text: "Hello"]
        }
      ])
    end

    test "parse for block with variable range" do
      "{% for i in (1..x) %}Hello{% endfor %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.ForTag},
          identifier: "i",
          collection: [inclusive_range: [begin: [literal: 1], end: [field: [key: "x"]]]],
          parameters: [],
          contents: [text: "Hello"]
        }
      ])
    end

    test "parse for block with reversed" do
      "{% for i in x reversed %}Hello{% endfor %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.ForTag},
          identifier: "i",
          collection: [field: [key: "x"]],
          parameters: [order: :reversed],
          contents: [text: "Hello"]
        }
      ])
    end

    test "parse for block with limit" do
      "{% for i in x limit:2 %}Hello{% endfor %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.ForTag},
          identifier: "i",
          collection: [field: [key: "x"]],
          parameters: [limit: 2],
          contents: [text: "Hello"]
        }
      ])
    end

    test "parse for block with offset" do
      "{% for i in x offset:1 %}Hello{% endfor %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.ForTag},
          identifier: "i",
          collection: [field: [key: "x"]],
          parameters: [offset: 1],
          contents: [text: "Hello"]
        }
      ])
    end

    test "parse for block with reverse, limit, and offset" do
      "{% for i in x reversed limit:2 offset:1 %}Hello{% endfor %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.ForTag},
          identifier: "i",
          collection: [field: [key: "x"]],
          parameters: [order: :reversed, limit: 2, offset: 1],
          contents: [text: "Hello"]
        }
      ])
    end
  end

  describe "render" do
    test "render basic for loop" do
      context =
        Context.new(%{
          "collection" => %{
            "products" => [
              %{"title" => "hat"},
              %{"title" => "shirt"},
              %{"title" => "pants"}
            ]
          }
        })

      {:ok, template} =
        """
        {% for product in collection.products %}
          {{ product.title }}
        {% endfor %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, context)
             |> elem(0)
             |> to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ["hat", "shirt", "pants"]
    end

    test "render loop with limit" do
      context = Context.new(%{"array" => [1, 2, 3, 4, 5, 6]})

      {:ok, template} =
        """
        {% for item in array limit:2 %}
          {{ item }}
        {% endfor %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, context)
             |> elem(0)
             |> to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ~w(1 2)
    end

    test "render loop with offset" do
      context = Context.new(%{"array" => [1, 2, 3, 4, 5, 6]})

      {:ok, template} =
        """
        {% for item in array offset:2 %}
          {{ item }}
        {% endfor %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, context)
             |> elem(0)
             |> to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ~w(3 4 5 6)
    end

    test "render loop with reverse" do
      context = Context.new(%{"array" => [1, 2, 3, 4, 5, 6]})

      {:ok, template} =
        """
        {% for item in array reversed %}
          {{ item }}
        {% endfor %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, context)
             |> elem(0)
             |> to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ~w(6 5 4 3 2 1)
    end

    test "render loop with all the things" do
      context = Context.new(%{"array" => [1, 2, 3, 4, 5, 6]})

      {:ok, template} =
        """
        {% for item in array reversed limit:2 offset:1 %}
          {{ item }}
        {% endfor %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, context)
             |> elem(0)
             |> to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ~w(5)
    end

    test "render loop with range" do
      {:ok, template} =
        """
        {% for i in (3..5) %}
          {{ i }}
        {% endfor %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, %Context{})
             |> elem(0)
             |> to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ~w(3 4 5)
    end

    test "render loop with range w/ field" do
      {:ok, template} =
        """
        {% for i in (1..num) %}
          {{ i }}
        {% endfor %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, Context.new(%{"num" => 4}))
             |> elem(0)
             |> to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ~w(1 2 3 4)
    end

    test "render for loop with forloop variable" do
      {:ok, template} =
        """
        {% for i in (1..3) %}
          {{ forloop.first }}
          {{ forloop.index }}
          {{ forloop.index0 }}
          {{ forloop.last }}
          {{ forloop.length }}
          {{ forloop.rindex }}
          {{ forloop.rindex0 }}
        {% endfor %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, %Context{})
             |> elem(0)
             |> to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ~w(true 1 0 false 3 3 2 false 2 1 false 3 2 1 false 3 2 true 3 1 0)
    end
  end

  defp trim_list(list) do
    list
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end
end
