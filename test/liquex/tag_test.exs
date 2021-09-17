defmodule Liquex.TagTest do
  @moduledoc false

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

      assert Liquex.render(template)
             |> elem(0)
             |> to_string()
             |> String.trim() ==
               "In Handlebars, {{ this }} will be HTML-escaped, but {{{ that }}} will not."
    end
  end
end
