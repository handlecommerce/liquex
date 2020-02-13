defmodule LiquexTest do
  use ExUnit.Case, async: true

  describe "render" do
    test "render simple text body" do
      {:ok, template} = Liquex.parse("Hello World")
      assert Liquex.render(template) == {["Hello World"], %{}}
    end

    test "render simple value" do
      context = %{"name" => "Tom"}
      {:ok, template} = Liquex.parse("Hello, {{ name }}")
      assert elem(Liquex.render(template, context), 0) == ["Hello, ", "Tom"]
    end

    test "render simple filter" do
      context = %{"name" => "tom"}
      {:ok, template} = Liquex.parse("Hello, {{ name | upcase }}")
      assert elem(Liquex.render(template, context), 0) == ["Hello, ", "TOM"]
    end

    test "if statement" do
      context = %{"product" => %{"title" => "Awesome Shoes"}}

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
             |> String.trim() == "These shoes are awesome!"
    end
  end
end
