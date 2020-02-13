defmodule Liquex.TagTest do
  use ExUnit.Case, async: true

  describe "raw" do
    test "parse raw properly" do
      {:ok, template} =
        """
        {% raw %}
          In Handlebars, {{ this }} will be HTML-escaped, but {{{ that }}} will not.
        {% endraw %}
        """
        |> Liquex.parse()

      assert Liquex.render(template, %{})
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim() == "This is a {{test}}"
    end
  end
end
