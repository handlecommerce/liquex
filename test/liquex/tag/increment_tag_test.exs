defmodule Liquex.Tag.IncrementTagTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  describe "parse" do
    test "parse increment" do
      "{% increment a %}"
      |> assert_parse([{{:tag, Liquex.Tag.IncrementTag}, [identifier: "a", by: 1]}])
    end

    test "parse decrement" do
      "{% decrement a %}"
      |> assert_parse([{{:tag, Liquex.Tag.IncrementTag}, [identifier: "a", by: -1]}])
    end
  end

  describe "render" do
    test "increments value" do
      {:ok, template} =
        """
        {% increment a %}
        {% increment a %}
        {% increment a %}
        {% increment b %}
        {% increment b %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, %{a: 10})
             |> elem(0)
             |> to_string()
             |> String.trim() == "10\n11\n12\n0\n1"
    end

    test "decrements value" do
      {:ok, template} =
        """
        {% assign a = 0 %}
        {% decrement a %}
        {% decrement a %}
        {% decrement a %}
        {% decrement b %}
        {% decrement b %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, %{a: 10})
             |> elem(0)
             |> to_string()
             |> String.trim() == "10\n9\n8\n0\n-1"
    end
  end
end
