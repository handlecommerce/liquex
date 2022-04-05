defmodule Liquex.Tag.IfTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  alias Liquex.Context

  describe "parse" do
    test "parse if block with boolean" do
      "{% if true %}Hello{% endif %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.If},
          expression: [literal: true], contents: [text: "Hello"]
        }
      ])
    end

    test "parse if block with conditional" do
      "{% if a == b %}Hello{% endif %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.If},
          expression: [[left: [field: [key: "a"]], op: :==, right: [field: [key: "b"]]]],
          contents: [text: "Hello"]
        }
      ])
    end

    test "parse if block with and" do
      "{% if true and false %}Hello{% endif %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.If},
          expression: [{:literal, true}, :and, {:literal, false}], contents: [text: "Hello"]
        }
      ])

      "{% if true or false %}Hello{% endif %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.If},
          expression: [{:literal, true}, :or, {:literal, false}], contents: [text: "Hello"]
        }
      ])

      "{% if true and false or true %}Hello{% endif %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.If},
          expression: [{:literal, true}, :and, {:literal, false}, :or, {:literal, true}],
          contents: [text: "Hello"]
        }
      ])

      "{% if a > b and b > c %}Hello{% endif %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.If},
          expression: [
            [left: [field: [key: "a"]], op: :>, right: [field: [key: "b"]]],
            :and,
            [left: [field: [key: "b"]], op: :>, right: [field: [key: "c"]]]
          ],
          contents: [text: "Hello"]
        }
      ])

      "{% if a and b > c %}Hello{% endif %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.If},
          expression: [
            {:field, [key: "a"]},
            :and,
            [left: [field: [key: "b"]], op: :>, right: [field: [key: "c"]]]
          ],
          contents: [text: "Hello"]
        }
      ])
    end

    test "parse if block with elsif" do
      "{% if true %}Hello{% elsif false %}Goodbye{% endif %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.If},
          expression: [literal: true],
          contents: [text: "Hello"],
          elsif: [expression: [literal: false], contents: [text: "Goodbye"]]
        }
      ])

      "{% if true %}Hello{% elsif false %}Goodbye{% elsif 1 %}Other{% endif %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.If},
          expression: [literal: true],
          contents: [text: "Hello"],
          elsif: [expression: [literal: false], contents: [text: "Goodbye"]],
          elsif: [expression: [literal: 1], contents: [text: "Other"]]
        }
      ])
    end

    test "parse if block with else" do
      "{% if true %}Hello{% else %}Goodbye{% endif %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.If},
          [
            expression: [literal: true],
            contents: [text: "Hello"],
            else: [contents: [text: "Goodbye"]]
          ]
        }
      ])
    end

    test "parse if block with ifelse and else" do
      "{% if true %}one{% elsif false %}two{% else %}three{% endif %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.If},
          expression: [literal: true],
          contents: [text: "one"],
          elsif: [expression: [literal: false], contents: [text: "two"]],
          else: [contents: [text: "three"]]
        }
      ])
    end

    test "kitchen sink" do
      """
        {% if customer.name == "kevin" %}
          Hey Kevin!
        {% elsif customer.name == "anonymous" %}
          Hey Anonymous!
        {% else %}
          Hi Stranger!
        {% endif %}
      """
      |> assert_parse([
        {:text, "  "},
        {
          {:tag, Liquex.Tag.If},
          [
            expression: [
              [
                left: [field: [key: "customer", key: "name"]],
                op: :==,
                right: [literal: "kevin"]
              ]
            ],
            contents: [text: "\n    Hey Kevin!\n  "],
            elsif: [
              expression: [
                [
                  left: [field: [key: "customer", key: "name"]],
                  op: :==,
                  right: [literal: "anonymous"]
                ]
              ],
              contents: [text: "\n    Hey Anonymous!\n  "]
            ],
            else: [contents: [text: "\n    Hi Stranger!\n  "]]
          ]
        },
        {:text, "\n"}
      ])
    end
  end

  describe "render" do
    test "failing if statement" do
      context = Context.new(%{"product" => %{"title" => "Not Awesome Shoes"}})

      {:ok, template} =
        """
        {% if product.title == "Awesome Shoes" %}
          These shoes are awesome!
        {% endif %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert elem(Liquex.render(template, context), 0)
             |> to_string()
             |> String.trim() == ""
    end

    test "else statement" do
      context = Context.new(%{"product" => %{"title" => "Not Awesome Shoes"}})

      {:ok, template} =
        """
        {% if product.title == "Awesome Shoes" %}
          These shoes are awesome!
        {% else %}
          These are {{ product.title }}
        {% endif %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert elem(Liquex.render(template, context), 0)
             |> to_string()
             |> String.trim() == "These are Not Awesome Shoes"
    end

    test "elsif statement" do
      context = Context.new(%{"product" => %{"id" => 2, "title" => "Not Awesome Shoes"}})

      {:ok, template} =
        """
        {% if product.title == "Awesome Shoes" %}
          These shoes are awesome!
        {% elsif product.id == 2 %}
          These are not awesome shoes
        {% else %}
          I don't know what these are
        {% endif %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert elem(Liquex.render(template, context), 0)
             |> to_string()
             |> String.trim() == "These are not awesome shoes"
    end

    test "or statement" do
      customer = %{"tags" => [], "email" => "example@mycompany.com"}

      {:ok, template} =
        """
        {% if customer.tags contains 'VIP' or customer.email contains 'mycompany.com' %}
          Welcome! We're pleased to offer you a special discount of 15% on all products.
        {% else %}
          Welcome to our store!
        {% endif %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, Context.new(%{"customer" => customer}))
             |> elem(0)
             |> to_string()
             |> String.trim() ==
               "Welcome! We're pleased to offer you a special discount of 15% on all products."
    end

    test "mixed or/and statement" do
      {:ok, template} =
        """
        {% if true and false or true %}
          It's true
        {% else %}
          It's not true
        {% endif %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, Context.new(%{}))
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim() ==
               "It's true"
    end
  end
end
