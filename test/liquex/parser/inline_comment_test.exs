defmodule Liquex.Parser.InlineCommentTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  test "Parses simple tag with inline comment" do
    assert_parse(
      "{% # Test %}",
      [{{:tag, Liquex.Tag.InlineCommentTag}, []}]
    )
  end

  test "Parses simple tag with multiple inline comment lines" do
    assert_parse(
      """
      {% # Test
      # Test 2 %}
      """
      |> String.trim(),
      [{{:tag, Liquex.Tag.InlineCommentTag}, []}]
    )
  end

  test "Parses simple tag with multiple inline comments, plus whitespace lines" do
    assert_parse(
      """
      {% # Test

      # Test 2 %}
      """
      |> String.trim(),
      [{{:tag, Liquex.Tag.InlineCommentTag}, []}]
    )
  end

  test "Does not parse when a line contains text without comment" do
    assert_parse_error(
      """
      {% # Test
      Test 2
      # Test %}
      """
      |> String.trim()
    )
  end

  test "Allows blank line before and after comment" do
    assert_parse(
      """
      {%
      # Test

      # Test 2
      %}
      """
      |> String.trim(),
      [{{:tag, Liquex.Tag.InlineCommentTag}, []}]
    )
  end

  test "Allows blank line before and after comment, with whitespace" do
    assert_parse(
      """
      {%
      # Test

      # Test 2
      %}
      """
      |> String.trim(),
      [{{:tag, Liquex.Tag.InlineCommentTag}, []}]
    )
  end

  describe "liquid tag" do
    test "Parses simple tag with inline comment" do
      assert_parse(
        "{% liquid # Test %}",
        [
          {{:tag, Liquex.Tag.LiquidTag},
           [{:contents, [{{:tag, Liquex.Tag.InlineCommentTag}, []}]}]}
        ]
      )
    end

    test "Parses simple tag with multiple inline comment lines" do
      assert_parse(
        """
        {% liquid # Test
        # Test 2 %}
        """
        |> String.trim(),
        [
          {{:tag, Liquex.Tag.LiquidTag},
           [
             {:contents,
              [
                {{:tag, Liquex.Tag.InlineCommentTag}, []},
                {{:tag, Liquex.Tag.InlineCommentTag}, []}
              ]}
           ]}
        ]
      )
    end

    test "parses complex liquid tag with comments and tags" do
      assert_parse(
        """
        {% liquid
          # this is a comment
          assign topic = 'Learning about comments!'
          echo topic
        %}
        """
        |> String.trim(),
        [
          {{:tag, Liquex.Tag.LiquidTag},
           [
             contents: [
               {{:tag, Liquex.Tag.InlineCommentTag}, []},
               {{:tag, Liquex.Tag.AssignTag},
                [left: "topic", right: [literal: "Learning about comments!", filters: []]]},
               {{:tag, Liquex.Tag.EchoTag}, [field: [key: "topic"], filters: []]}
             ]
           ]}
        ]
      )
    end
  end
end
