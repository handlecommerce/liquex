defmodule Liquex.Render.IterationTest do
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

    test "render for loop with forloop variable" do
      {:ok, template} =
        """
        {% for i in (1..3) %}
          {{ forloop.first }}
          {{ forloop.index }}
          {{ forloop.index0 }}
          {{ forloop.last }}
          {{ forloop.length }}
          {{ forloop.rindex }}
          {{ forloop.rindex0 }}
        {% endfor %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, %Context{})
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ~w(true 1 0 false 3 3 2 false 2 1 false 3 2 1 false 3 2 true 3 1 0)
    end
  end

  describe "break" do
    test "break out of for loop" do
      {:ok, template} =
        """
        {% for i in (1..5) %}
        {% if i == 4 %}
          {% break %}
        {% else %}
          {{ i }}
        {% endif %}
        {% endfor %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, %Context{})
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ~w(1 2 3)
    end

    test "continue out of for loop" do
      {:ok, template} =
        """
        {% for i in (1..5) %}
        {% if i == 4 %}
          {% continue %}
        {% else %}
          {{ i }}
        {% endif %}
        {% endfor %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, %Context{})
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ~w(1 2 3 5)
    end
  end

  describe "cycle" do
    test "simple cycle" do
      {:ok, template} =
        """
        {% cycle "one", "two", "three" %}
        {% cycle "one", "two", "three" %}
        {% cycle "one", "two", "three" %}
        {% cycle "one", "two", "three" %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, %Context{})
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ~w(one two three one)
    end

    test "named cycle" do
      {:ok, template} =
        """
        {% cycle "first": "one", "two", "three" %}
        {% cycle "second": "one", "two", "three" %}
        {% cycle "second": "one", "two", "three" %}
        {% cycle "first": "one", "two", "three" %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, %Context{})
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ~w(one one two two)
    end
  end

  describe "tablerow" do
    test "simple tablerow" do
      {:ok, template} =
        """
        <table>
        {% tablerow product in collection %}
          {{ product }}
        {% endtablerow %}
        </table>
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, Context.new(%{"collection" => [1, 2, 3]}))
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list()
             |> Enum.join() ==
               "<table><tr><td>1</td></tr><tr><td>2</td></tr><tr><td>3</td></tr></table>"
    end

    test "tablerow with cols" do
      {:ok, template} =
        """
        <table>
        {% tablerow product in collection cols:2 %}
          {{ product }}
        {% endtablerow %}
        </table>
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, Context.new(%{"collection" => [1, 2, 3]}))
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list()
             |> Enum.join() ==
               "<table><tr><td>1</td><td>2</td></tr><tr><td>3</td><td></td></tr></table>"
    end
  end

  defp trim_list(list) do
    list
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end
end
