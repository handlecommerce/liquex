defmodule Liquex.Render.ControlFlowTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Liquex.Context

  describe "case statements" do
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

      assert Liquex.render(template, Context.new(%{"name" => "James"}))
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello, James!"

      assert Liquex.render(template, Context.new(%{"name" => "John"}))
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello, John!"

      assert Liquex.render(template, Context.new(%{"name" => "Peter"}))
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello, Peter or Paul (cannot tell you apart)."

      assert Liquex.render(template, Context.new(%{"name" => "Paul"}))
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello, Peter or Paul (cannot tell you apart)."

      assert Liquex.render(template, Context.new(%{"name" => "Jim"}))
             |> elem(0)
             |> to_string()
             |> String.trim() == "Hello! Who are you?"
    end
  end
end
