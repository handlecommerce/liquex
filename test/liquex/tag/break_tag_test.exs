defmodule Liquex.Tag.BreakTagTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  describe "parse" do
    test "basic break" do
      "{% for i in x %}{% if i == 2 %}{% break %}{% endif %}Hello{% endfor %}"
      |> assert_parse([
        {
          {:tag, Liquex.Tag.ForTag},
          [
            {:identifier, "i"},
            {:collection, [field: [key: "x"]]},
            {:parameters, []},
            {:contents,
             [
               {{:tag, Liquex.Tag.IfTag},
                [
                  expression: [[left: [field: [key: "i"]], op: :==, right: [literal: 2]]],
                  contents: [{{:tag, Liquex.Tag.BreakTag}, []}]
                ]},
               {:text, "Hello"}
             ]}
          ]
        }
      ])
    end
  end

  describe "render" do
    test "basic break" do
      {:ok, template} =
        "{% for i in x %}{% if i > 2 %}{% break %}{% endif %}Hello{% endfor %}"
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, %{"x" => 1..40})
             |> elem(0)
             |> to_string() == "HelloHello"
    end

    test "does not throw away current buffer" do
      {:ok, template} =
        "{% for i in (1..5) %}{{ i }}{% if i > 2 %}{% break %}{% endif %}{% endfor %}"
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, %{})
             |> elem(0)
             |> to_string() == "123"
    end
  end
end
