defmodule Liquex.Tag.CaseTagTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  alias Liquex.Context

  describe "parse" do
    test "parse simple case statement" do
      "{% case a %} {% when 1 %}test{% endcase %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.CaseTag},
          field: [key: "a"], when: [expression: [literal: 1], contents: [text: "test"]]
        }
      ])
    end

    test "parse multiple case statement" do
      "{% case a %} {% when 1 %}test{% when 2 %}test2{% endcase %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.CaseTag},
          field: [key: "a"],
          when: [expression: [literal: 1], contents: [text: "test"]],
          when: [expression: [literal: 2], contents: [text: "test2"]]
        }
      ])
    end

    test "parse case with else statement" do
      "{% case a %} {% when 1 %} test {% else %} test2 {% endcase %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.CaseTag},
          field: [key: "a"],
          when: [expression: [literal: 1], contents: [text: " test "]],
          else: [contents: [text: " test2 "]]
        }
      ])
    end

    test "kitchen sink" do
      """
      {% case handle %}
        {% when "cake" %}
          This is a cake
        {% when "cookie" %}
          This is a cookie
        {% else %}
          This is not a cake nor a cookie
      {% endcase %}
      """
      |> assert_parse([
        {
          {:tag, Liquex.Tag.CaseTag},
          field: [key: "handle"],
          when: [expression: [literal: "cake"], contents: [text: "\n    This is a cake\n  "]],
          when: [
            expression: [literal: "cookie"],
            contents: [text: "\n    This is a cookie\n  "]
          ],
          else: [contents: [text: "\n    This is not a cake nor a cookie\n"]]
        },
        {:text, "\n"}
      ])
    end
  end

  describe "render" do
    test "simple case" do
      {:ok, template} =
        """
        {% case name %}
          {% when "James" %}
            Hello, James!
          {% when "John" %}
            Hello, John!
          {% when "Peter", "Paul" %}
            Hello, Peter or Paul (cannot tell you apart).
          {% else %}
            Hello! Who are you?
        {% endcase %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render!(template, Context.new(%{"name" => "James"}))
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello, James!"

      assert Liquex.render!(template, Context.new(%{"name" => "John"}))
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello, John!"

      assert Liquex.render!(template, Context.new(%{"name" => "Peter"}))
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello, Peter or Paul (cannot tell you apart)."

      assert Liquex.render!(template, Context.new(%{"name" => "Paul"}))
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello, Peter or Paul (cannot tell you apart)."

      assert Liquex.render!(template, Context.new(%{"name" => "Jim"}))
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello! Who are you?"
    end
  end

  describe "render with liquid tag" do
    test "simple case" do
      {:ok, template} =
        """
        {% liquid case name
          when "James"
            echo "Hello, James!"
          when "John"
            echo "Hello, John!"
          when "Peter", "Paul"
            echo "Hello, Peter or Paul (cannot tell you apart)."
          else
            echo "Hello! Who are you?"
        endcase %}
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render!(template, Context.new(%{"name" => "James"}))
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello, James!"

      assert Liquex.render!(template, Context.new(%{"name" => "John"}))
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello, John!"

      assert Liquex.render!(template, Context.new(%{"name" => "Peter"}))
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello, Peter or Paul (cannot tell you apart)."

      assert Liquex.render!(template, Context.new(%{"name" => "Paul"}))
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello, Peter or Paul (cannot tell you apart)."

      assert Liquex.render!(template, Context.new(%{"name" => "Jim"}))
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello! Who are you?"
    end
  end
end
