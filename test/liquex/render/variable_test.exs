defmodule Liquex.Render.VariableTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Liquex.Context

  describe "assign" do
    test "assign simple value" do
      context = %Context{}

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
             |> IO.chardata_to_string()
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
             |> IO.chardata_to_string()
             |> String.trim() == "5"
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

      assert Liquex.render(template, %Context{})
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim() == "Hello World!"
    end

    test "capture text as string" do
      {:ok, template} =
        """
        {% assign hello = "Hello" %}
        {% capture a %}
        {{ hello }} World!
        {% endcapture %}
        """
        |> String.trim()
        |> Liquex.parse()

      {_, %Liquex.Context{variables: variables}} = Liquex.render(template, %Context{})

      assert variables["a"]
             |> String.trim() == "Hello World!"
    end
  end

  describe "increment" do
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
             |> IO.chardata_to_string()
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
             |> IO.chardata_to_string()
             |> String.trim() == "7--2"
    end
  end
end
