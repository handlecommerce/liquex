defmodule Liquex.Render.IterationTestt do
  use ExUnit.Case, async: true

  alias Liquex.Context

  describe "for" do
    test "render basic for loop" do
      context =
        Context.new(%{
          "collection" => %{
            "products" => [
              %{"title" => "hat"},
              %{"title" => "shirt"},
              %{"title" => "pants"}
            ]
          }
        })

      {:ok, template} =
        """
        {% for product in collection.products %}
          {{ product.title }}
        {% endfor %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, context)
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ["hat", "shirt", "pants"]
    end

    test "render loop with limit" do
      context = Context.new(%{"array" => [1, 2, 3, 4, 5, 6]})

      {:ok, template} =
        """
        {% for item in array limit:2 %}
          {{ item }}
        {% endfor %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, context)
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ~w(1 2)
    end

    test "render loop with offset" do
      context = Context.new(%{"array" => [1, 2, 3, 4, 5, 6]})

      {:ok, template} =
        """
        {% for item in array offset:2 %}
          {{ item }}
        {% endfor %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, context)
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ~w(3 4 5 6)
    end

    test "render loop with reverse" do
      context = Context.new(%{"array" => [1, 2, 3, 4, 5, 6]})

      {:ok, template} =
        """
        {% for item in array reversed %}
          {{ item }}
        {% endfor %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, context)
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ~w(6 5 4 3 2 1)
    end

    test "render loop with all the things" do
      context = Context.new(%{"array" => [1, 2, 3, 4, 5, 6]})

      {:ok, template} =
        """
        {% for item in array reversed limit:2 offset:1 %}
          {{ item }}
        {% endfor %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, context)
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ~w(5)
    end

    test "render loop with range" do
      {:ok, template} =
        """
        {% for i in (3..5) %}
          {{ i }}
        {% endfor %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, %Context{})
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ~w(3 4 5)
    end

    test "render loop with range w/ field" do
      {:ok, template} =
        """
        {% for i in (1..num) %}
          {{ i }}
        {% endfor %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, Context.new(%{"num" => 4}))
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ~w(1 2 3 4)
    end
  end

  # describe "cycle" do
  #   test "simple cycle" do
  #     {:ok, template} =
  #       """
  #       {% cycle "one", "two", "three" %}
  #       {% cycle "one", "two", "three" %}
  #       {% cycle "one", "two", "three" %}
  #       {% cycle "one", "two", "three" %}
  #       """
  #       |> String.trim()
  #       |> Liquex.parse()

  #     assert Liquex.render(template, %Context{})
  #            |> elem(0)
  #            |> IO.chardata_to_string()
  #            |> String.trim()
  #            |> String.split("\n")
  #            |> trim_list() == ~w(one two three one)
  #   end
  # end

  defp trim_list(list) do
    list
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end
end
