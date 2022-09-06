defmodule Liquex.Tag.RenderTagTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  alias Liquex.TestHelpers.MockFileSystem

  describe "parse" do
    test "parses render with file" do
      assert_parse(
        "{% render 'template-name' %}",
        [{{:tag, Liquex.Tag.RenderTag}, template: {:literal, "template-name"}}]
      )
    end

    test "parses render containing parameters" do
      assert_parse(
        "{% render \"name\", my_variable: my_variable, my_other_variable: \"oranges\" %}",
        [
          {{:tag, Liquex.Tag.RenderTag},
           [
             template: {:literal, "name"},
             keyword: ["my_variable", {:field, [key: "my_variable"]}],
             keyword: ["my_other_variable", {:literal, "oranges"}]
           ]}
        ]
      )
    end

    test "parses render containing `with`" do
      assert_parse(
        "{% render 'product' with products[0] %}",
        [
          {{:tag, Liquex.Tag.RenderTag},
           [
             template: {:literal, "product"},
             with: [field: [key: "products", accessor: {:literal, 0}]]
           ]}
        ]
      )
    end

    test "parses render containing `with` and alias" do
      assert_parse(
        "{% render 'product_alias' with products[0] as product %}",
        [
          {{:tag, Liquex.Tag.RenderTag},
           [
             template: {:literal, "product_alias"},
             with: [field: [key: "products", accessor: {:literal, 0}], as: "product"]
           ]}
        ]
      )
    end

    test "parses render with for loop" do
      assert_parse(
        "{% render 'product' for products %}",
        [
          {{:tag, Liquex.Tag.RenderTag},
           [template: {:literal, "product"}, for: [collection: {:field, [key: "products"]}]]}
        ]
      )
    end

    test "parses render with for loop and alias" do
      assert_parse(
        "{% render 'product_alias' for products as product %}",
        [
          {{:tag, Liquex.Tag.RenderTag},
           [
             template: {:literal, "product_alias"},
             for: [collection: {:field, [key: "products"]}, as: "product"]
           ]}
        ]
      )
    end
  end

  describe "render" do
    test "renders external template" do
      context =
        Liquex.Context.new(%{}, file_system: MockFileSystem.new(%{"source" => "rendered content"}))

      {:ok, template} = "{% render 'source' %}" |> Liquex.parse()

      assert Liquex.render(template, context)
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim() == "rendered content"
    end
  end
end
