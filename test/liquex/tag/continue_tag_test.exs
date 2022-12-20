defmodule Liquex.Tag.ContinueTagTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  describe "parse" do
    test "basic continue" do
      "{% for i in x %}{% if i == 2 %}{% continue %}{% endif %}Hello{% endfor %}"
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
                  contents: [{{:tag, Liquex.Tag.ContinueTag}, []}]
                ]},
               {:text, "Hello"}
             ]}
          ]
        }
      ])
    end
  end

  describe "render" do
    test "ignore comments in render" do
      {:ok, template} =
        "{% for i in x %}{% if i > 2 %}{% continue %}{% endif %}Hello{% endfor %}"
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, %{"x" => 1..40})
             |> elem(0)
             |> to_string() == "HelloHello"

      assert render(
               """
                 {% liquid for i in x
                   if i > 2
                     continue
                   endif

                   echo "Hello"
                 endfor %}
               """,
               Liquex.Context.new(%{"x" => 1..40})
             ) == "HelloHello"
    end
  end
end
