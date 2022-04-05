defmodule Liquex.Tag.UnlessTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  alias Liquex.Context

  describe "parse" do
    test "parse unless block with boolean" do
      "{% unless true %}Hello{% endunless %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.Unless},
          expression: [literal: true], contents: [text: "Hello"]
        }
      ])
    end

    test "parse unless block with conditional" do
      "{% unless a == b %}Hello{% endunless %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.Unless},
          expression: [[left: [field: [key: "a"]], op: :==, right: [field: [key: "b"]]]],
          contents: [text: "Hello"]
        }
      ])
    end

    test "parse unless block with and" do
      "{% unless true and false %}Hello{% endunless %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.Unless},
          expression: [{:literal, true}, :and, {:literal, false}], contents: [text: "Hello"]
        }
      ])

      "{% unless true or false %}Hello{% endunless %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.Unless},
          expression: [{:literal, true}, :or, {:literal, false}], contents: [text: "Hello"]
        }
      ])

      "{% unless a > b and b > c %}Hello{% endunless %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.Unless},
          expression: [
            [left: [field: [key: "a"]], op: :>, right: [field: [key: "b"]]],
            :and,
            [left: [field: [key: "b"]], op: :>, right: [field: [key: "c"]]]
          ],
          contents: [text: "Hello"]
        }
      ])
    end

    test "parse unless block with elsif" do
      "{% unless true %}Hello{% elsif false %}Goodbye{% endunless %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.Unless},
          expression: [literal: true],
          contents: [text: "Hello"],
          elsif: [expression: [literal: false], contents: [text: "Goodbye"]]
        }
      ])

      "{% unless true %}Hello{% elsif false %}Goodbye{% elsif 1 %}Other{% endunless %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.Unless},
          expression: [literal: true],
          contents: [text: "Hello"],
          elsif: [expression: [literal: false], contents: [text: "Goodbye"]],
          elsif: [expression: [literal: 1], contents: [text: "Other"]]
        }
      ])
    end

    test "parse unless block with else" do
      "{% unless true %}Hello{% else %}Goodbye{% endunless %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.Unless},
          expression: [literal: true],
          contents: [text: "Hello"],
          else: [contents: [text: "Goodbye"]]
        }
      ])
    end

    test "parse unless block with ifelse and else" do
      "{% unless true %}one{% elsif false %}two{% else %}three{% endunless %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.Unless},
          expression: [literal: true],
          contents: [text: "one"],
          elsif: [expression: [literal: false], contents: [text: "two"]],
          else: [contents: [text: "three"]]
        }
      ])
    end
  end

  describe "render" do
    test "simple unless" do
      {:ok, template} =
        """
        {% unless product.title == "Awesome Shoes" %}
          These shoes are not awesome.
        {% else %}
          These shoes ARE awesome.
        {% endunless %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, Context.new(%{"product" => %{"title" => "Awesome Shoes"}}))
             |> elem(0)
             |> to_string()
             |> String.trim() == "These shoes ARE awesome."

      assert Liquex.render(
               template,
               Context.new(%{"product" => %{"title" => "Not Awesome Shoes"}})
             )
             |> elem(0)
             |> to_string()
             |> String.trim() == "These shoes are not awesome."
    end
  end
end
