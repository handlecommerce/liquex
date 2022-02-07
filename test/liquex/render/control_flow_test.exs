defmodule Liquex.Render.ControlFlowTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Liquex.Context

  describe "if statements" do
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

  describe "unless statements" do
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

  describe "case statements" do
    test "simple case" do
      {:ok, template} =
        """
        {% case name %}
          {% when "James" %}
            Hello, James!
          {% when "John" %}
            Hello, John!
          {% when "Peter", "Paul" %}
            Hello, Peter or Paul (cannot tell you apart).
          {% else %}
            Hello! Who are you?
        {% endcase %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, Context.new(%{"name" => "James"}))
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello, James!"

      assert Liquex.render(template, Context.new(%{"name" => "John"}))
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello, John!"

      assert Liquex.render(template, Context.new(%{"name" => "Peter"}))
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello, Peter or Paul (cannot tell you apart)."

      assert Liquex.render(template, Context.new(%{"name" => "Paul"}))
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello, Peter or Paul (cannot tell you apart)."

      assert Liquex.render(template, Context.new(%{"name" => "Jim"}))
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello! Who are you?"
    end
  end
end
