defmodule Liquex.Tag.CycleTagTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  alias Liquex.Context

  describe "parse" do
    test "parse cycle block with string sequence" do
      "{% cycle 'a', 'b', 'c' %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.CycleTag},
          sequence: [literal: "a", literal: "b", literal: "c"]
        }
      ])
    end

    test "parse cycle block with arguments" do
      "{% cycle a, b, c %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.CycleTag},
          sequence: [field: [key: "a"], field: [key: "b"], field: [key: "c"]]
        }
      ])
    end

    test "parse cycle block with cycle group" do
      "{% cycle 'group': 'a', 'b', 'c' %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.CycleTag},
          group: {:literal, "group"}, sequence: [literal: "a", literal: "b", literal: "c"]
        }
      ])
    end
  end

  describe "render" do
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

      assert Liquex.render!(template, %Context{})
             |> elem(0)
             |> to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ~w(one two three one)

      assert render("""
             {% liquid
             cycle "one", "two", "three"
             cycle "one", "two", "three"
             cycle "one", "two", "three"
             cycle "one", "two", "three"
             %}
             """) == "onetwothreeone"
    end

    test "cycle group can be a variable" do
      ctx = Context.new(%{"g" => "first", "h" => "second"})

      # Same variable, three calls cycle through.
      assert render(~s({% cycle g: 1, 2, 3 %}{% cycle g: 1, 2, 3 %}{% cycle g: 1, 2, 3 %}), ctx) ==
               "123"

      # Different group keys (different variable values) keep independent state.
      assert render(
               ~s({% cycle g: 1, 2 %}{% cycle h: 1, 2 %}{% cycle g: 1, 2 %}{% cycle h: 1, 2 %}),
               ctx
             ) == "1122"
    end

    test "different variables resolving to the same key share cycle state" do
      ctx = Context.new(%{"a" => "shared", "b" => "shared"})

      assert render(~s({% cycle a: 1, 2 %}{% cycle b: 1, 2 %}), ctx) == "12"
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

      assert Liquex.render!(template, %Context{})
             |> elem(0)
             |> to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list() == ~w(one one two two)

      assert render("""
             {% liquid
               cycle "first": "one", "two", "three"
               cycle "second": "one", "two", "three"
               cycle "second": "one", "two", "three"
               cycle "first": "one", "two", "three"
             %}
             """) == "oneonetwotwo"
    end
  end

  defp trim_list(list) do
    list
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end
end
