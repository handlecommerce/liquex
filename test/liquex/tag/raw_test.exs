defmodule Liquex.Tag.RawTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  describe "parse" do
    test "parses raw" do
      assert_parse(
        "{% raw %} {{ test }} {% endraw %}",
        [{{:tag, Liquex.Tag.Raw}, [" {{ test }} "]}]
      )

      assert_parse(
        "{% raw %} {{ test }} {% tag %} {% endraw %}",
        [{{:tag, Liquex.Tag.Raw}, [" {{ test }} {% tag %} "]}]
      )
    end
  end

  describe "render" do
    test "parse raw properly" do
      {:ok, template} =
        """
        {% raw %}
          In Handlebars, {{ this }} will be HTML-escaped, but {{{ that }}} will not.
        {% endraw %}
        """
        |> Liquex.parse()

      assert Liquex.render(template)
             |> elem(0)
             |> to_string()
             |> String.trim() ==
               "In Handlebars, {{ this }} will be HTML-escaped, but {{{ that }}} will not."
    end
  end
end
