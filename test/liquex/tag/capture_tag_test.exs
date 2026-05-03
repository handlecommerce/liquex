defmodule Liquex.Tag.CaptureTagTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  alias Liquex.Context

  describe "parse" do
    test "parse simple capture" do
      "{% capture a %}This is a test{% endcapture %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.CaptureTag},
          [identifier: "a", contents: [text: "This is a test"]]
        }
      ])
    end
  end

  describe "render" do
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

      assert Liquex.render!(template)
             |> elem(0)
             |> to_string()
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

      {_, context} = Liquex.render!(template)

      assert Context.fetch(context, "a") |> elem(1) |> String.trim() == "Hello World!"
    end

    test "capture inside a for loop persists in the outer scope" do
      {:ok, template} =
        """
        {% for i in (1..1) %}{% capture greeting %}Hello {{ i }}{% endcapture %}{% endfor %}
        {{ greeting }}
        """
        |> String.trim()
        |> Liquex.parse()

      {result, context} = Liquex.render!(template)

      assert result |> to_string() |> String.trim() == "Hello 1"
      assert Context.fetch(context, "greeting") |> elem(1) == "Hello 1"
    end
  end
end
