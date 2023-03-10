defmodule LiquexTest do
  use ExUnit.Case, async: true

  alias Liquex.Context

  describe "render" do
    test "render simple text body" do
      {:ok, template} = Liquex.parse("Hello World")

      assert Liquex.render!(template) |> elem(0) == ["Hello World"]
    end

    test "render simple value" do
      context = Context.new(%{"name" => "Tom"})
      {:ok, template} = Liquex.parse("Hello, {{ name }}")
      assert elem(Liquex.render!(template, context), 0) == ["Hello, ", "Tom"]
    end

    test "render simple filter" do
      context = Context.new(%{"name" => "tom"})
      {:ok, template} = Liquex.parse("Hello, {{ name | upcase }}")
      assert elem(Liquex.render!(template, context), 0) == ["Hello, ", "TOM"]
    end

    test "if statement" do
      context = Context.new(%{"product" => %{"title" => "Awesome Shoes"}})

      {:ok, template} =
        """
        {% if product.title == "Awesome Shoes" %}
          These shoes are awesome!
        {% endif %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert template
             |> Liquex.render!(context)
             |> elem(0)
             |> to_string()
             |> String.trim() == "These shoes are awesome!"
    end
  end
end
