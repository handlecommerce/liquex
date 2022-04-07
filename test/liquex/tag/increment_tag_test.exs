defmodule Liquex.Tag.IncrementTagTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  alias Liquex.Context

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
        {% assign a = 10 %}
        {% increment a %}
        {% increment a %}
        {% increment a %}
        {% increment b %}
        {% increment b %}
        {{ a }}-{{ b }}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, %Context{})
             |> elem(0)
             |> to_string()
             |> String.trim() == "13-2"
    end

    test "decrements value" do
      {:ok, template} =
        """
        {% assign a = 10 %}
        {% decrement a %}
        {% decrement a %}
        {% decrement a %}
        {% decrement b %}
        {% decrement b %}
        {{ a }}-{{ b }}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, %Context{})
             |> elem(0)
             |> to_string()
             |> String.trim() == "7--2"
    end
  end
end
