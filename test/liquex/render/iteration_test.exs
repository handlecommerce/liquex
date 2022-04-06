defmodule Liquex.Render.IterationTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Liquex.Context

  describe "tablerow" do
    test "simple tablerow" do
      {:ok, template} =
        """
        <table>
        {% tablerow product in collection %}
          {{ product }}
        {% endtablerow %}
        </table>
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, Context.new(%{"collection" => [1, 2, 3]}))
             |> elem(0)
             |> to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list()
             |> Enum.join() ==
               "<table><tr><td>1</td></tr><tr><td>2</td></tr><tr><td>3</td></tr></table>"
    end

    test "tablerow with cols" do
      {:ok, template} =
        """
        <table>
        {% tablerow product in collection cols:2 %}
          {{ product }}
        {% endtablerow %}
        </table>
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, Context.new(%{"collection" => [1, 2, 3]}))
             |> elem(0)
             |> to_string()
             |> String.trim()
             |> String.split("\n")
             |> trim_list()
             |> Enum.join() ==
               "<table><tr><td>1</td><td>2</td></tr><tr><td>3</td><td></td></tr></table>"
    end
  end

  defp trim_list(list) do
    list
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end
end
