defmodule Liquex.VariableTest do
  use ExUnit.Case, async: true

  describe "assign" do
    test "assign simple value" do
      context = %{}

      {:ok, template} =
        """
        {% assign a = "Hello World!" %}
        {{ a }}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, context)
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim() == "Hello World!"
    end

    test "assign another field" do
      context = %{"a" => %{"b" => "Hello World!"}}

      {:ok, template} =
        """
        {% assign c = a.b %}
        {{ c }}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, context)
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim() == "Hello World!"
    end
  end

  describe "capture" do
    test "capture simple text" do
      {:ok, template} =
        """
        {% capture a %}
        Hello World!
        {% endcapture %}
        {{ a }}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, %{})
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim() == "Hello World!"
    end
  end

  describe "increment" do
    test "increments unknown value" do
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

      assert Liquex.render(template, %{})
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim() == "13-2"
    end
  end
end
