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

      assert Liquex.render(template)
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

      {_, context} = Liquex.render(template)

      assert Context.fetch(context, "a") |> elem(1) |> String.trim() == "Hello World!"
    end
  end
end
