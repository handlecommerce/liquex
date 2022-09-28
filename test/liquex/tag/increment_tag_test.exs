defmodule Liquex.Tag.IncrementTagTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  describe "parse" do
    test "parse increment" do
      "{% increment a %}"
      |> assert_parse([{{:tag, Liquex.Tag.IncrementTag}, [identifier: "a", by: {0, 1}]}])
    end

    test "parse decrement" do
      "{% decrement a %}"
      |> assert_parse([{{:tag, Liquex.Tag.IncrementTag}, [identifier: "a", by: {-1, -1}]}])
    end

    test "parse increment without variable" do
      assert_parse("{% increment %}", [{{:tag, Liquex.Tag.IncrementTag}, [by: {0, 1}]}])
      assert_parse("{% decrement %}", [{{:tag, Liquex.Tag.IncrementTag}, [by: {-1, -1}]}])
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

      assert render(
               """
                 {% liquid
                   increment a
                   increment a
                   increment a
                   increment b
                   increment b
                 %}
               """,
               Liquex.Context.new(%{a: 10})
             ) == "10111201"
    end

    test "increments default key" do
      {:ok, template} =
        "{% increment %} {% increment %} {% increment %}"
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template)
             |> elem(0)
             |> to_string()
             |> String.trim() == "0 1 2"

      assert render("""
               {% liquid
                 increment
                 increment
                 increment %}
             """) == "012"
    end

    test "decrement from default key" do
      {:ok, template} =
        "{% decrement %} {% decrement %} {% decrement %}"
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template)
             |> elem(0)
             |> to_string()
             |> String.trim() == "-1 -2 -3"

      assert render("""
               {% liquid
                 decrement
                 decrement
                 decrement %}
             """) == "-1-2-3"
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
             |> String.trim() == "10\n9\n8\n-1\n-2"

      assert render(
               """
                {% liquid
                  assign a = 0
                  decrement a
                  decrement a
                  decrement a
                  decrement b
                  decrement b
                %}
               """,
               Liquex.Context.new(%{a: 10})
             ) == "1098-1-2"
    end
  end
end
