defmodule Liquex.ControlFlowTest do
  use ExUnit.Case, async: true

  describe "if statements" do
    test "failing if statement" do
      context = %{"product" => %{"title" => "Not Awesome Shoes"}}

      {:ok, template} =
        """
        {% if product.title == "Awesome Shoes" %}
          These shoes are awesome!
        {% endif %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert elem(Liquex.render(template, context), 0)
             |> IO.chardata_to_string()
             |> String.trim() == ""
    end

    test "else statement" do
      context = %{"product" => %{"title" => "Not Awesome Shoes"}}

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
             |> IO.chardata_to_string()
             |> String.trim() == "These are Not Awesome Shoes"
    end

    test "elsif statement" do
      context = %{"product" => %{"id" => 2, "title" => "Not Awesome Shoes"}}

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
             |> IO.chardata_to_string()
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

      assert Liquex.render(template, %{"customer" => customer})
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim() ==
               "Welcome! We're pleased to offer you a special discount of 15% on all products."
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

      assert Liquex.render(template, %{"product" => %{"title" => "Awesome Shoes"}})
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim() == "These shoes ARE awesome."

      assert Liquex.render(template, %{"product" => %{"title" => "Not Awesome Shoes"}})
             |> elem(0)
             |> IO.chardata_to_string()
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
          {% else %}
            Hello! Who are you?
        {% endcase %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, %{"name" => "James"})
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim() == "Hello, James!"

      assert Liquex.render(template, %{"name" => "John"})
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim() == "Hello, John!"

      assert Liquex.render(template, %{"name" => "Jim"})
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim() == "Hello! Who are you?"
    end
  end
end
