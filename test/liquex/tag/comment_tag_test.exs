defmodule Liquex.Tag.CommentTagTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  describe "parse" do
    test "simple parse" do
      assert_parse(
        "Hello {% comment %}Ignored text{% endcomment %} World",
        [{:text, "Hello "}, {{:tag, Liquex.Tag.CommentTag}, []}, {:text, " World"}]
      )
    end
  end

  describe "render" do
    test "ignore comments in render" do
      {:ok, template} =
        "Hello {% comment %} Ignored {% endcomment %} World"
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render!(template, %{})
             |> elem(0)
             |> to_string() == "Hello  World"
    end
  end
end
