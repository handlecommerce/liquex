defmodule Liquex.Tag.RenderTagTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  alias Liquex.MockFileSystem

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
             keywords: [
               keyword: ["my_variable", {:field, [key: "my_variable"]}],
               keyword: ["my_other_variable", {:literal, "oranges"}]
             ]
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

  def context(files, scope) do
    Liquex.Context.new(scope, file_system: MockFileSystem.new(files))
  end

  def render_with_files(template, files, scope \\ %{}) do
    {:ok, template} = Liquex.parse(template)

    Liquex.render(template, context(files, scope))
    |> elem(0)
    |> IO.chardata_to_string()
    |> String.trim()
  end

  describe "render" do
    test "renders external template" do
      assert render_with_files("{% render 'source' %}", %{"source" => "rendered content"}) ==
               "rendered content"
    end

    test "render passes named arguments into inner scope" do
      files = %{"product" => "{{ inner_product.title }}"}

      assert render_with_files("{% render 'product', inner_product: outer_product %}", files, %{
               "outer_product" => %{"title" => "My Product"}
             }) == "My Product"
    end

    test "render does not pass outer scope arguments into inner scope" do
      files = %{"snippet" => "{{ outer_variable }}"}

      assert render_with_files(
               "{% assign outer_variable = 'should not be visible' %}{% render 'snippet' %}",
               files
             ) == ""
    end

    test "render accepts literals as arguments" do
      files = %{"snippet" => "{{ price }}"}

      assert render_with_files("{% render 'snippet', price: 123 %}", files) == "123"
    end

    test "render accepts multiple named arguments" do
      files = %{"snippet" => "{{ one }} {{ two }}"}

      assert render_with_files("{% render 'snippet', one: 1, two: 2 %}", files) == "1 2"
    end

    test "render does not inherit variable with same name as snippet" do
      files = %{"snippet" => "{{ snippet }}"}

      assert render_with_files(
               "{% assign snippet = 'should not be visible' %}{% render 'snippet' %}",
               files
             ) ==
               ""
    end

    test "render does not mutate parent scope" do
      files = %{"snippet" => "{% assign inner = 1 %}"}
      assert render_with_files("{% render 'snippet' %}{{ inner }}", files) == ""
    end

    test "render handles nested render tags" do
      files = %{"one" => "one {% render 'two' %}", "two" => "two"}
      assert render_with_files("{% render 'one' %}", files) == "one two"
    end

    test "render allows access to static environment" do
      files = %{"snippet" => "{{ variable }}"}

      context =
        Liquex.Context.new(%{variable: "dynamic"},
          static_environment: %{variable: "static"},
          file_system: MockFileSystem.new(files)
        )

      {:ok, template} = Liquex.parse("{% render 'snippet' %} {{ variable }}")

      assert Liquex.render(template, context)
             |> elem(0)
             |> IO.chardata_to_string()
             |> String.trim() == "static dynamic"
    end

    @tag :skip
    test "recursive render does not produce endless loop"
    @tag :skip
    test "sub contexts count towards the same recursion limit"

    test "dynamically chosen templates are not allowed" do
      assert_parse_error("{% assign name = 'snippet' %}{% render name %}")
    end

    test "render tag within if statement" do
      files = %{"snippet" => "my message"}

      assert render_with_files("{% if true %}{% render 'snippet' %}{% endif %}", files) ==
               "my message"
    end

    test "break through render" do
      files = %{"break" => "{% break %}"}

      assert render_with_files(
               "{% for i in (1..3) %}{{ i }}{% break %}{{ i }}{% endfor %}",
               files
             ) == "1"

      assert render_with_files(
               "{% for i in (1..3) %}{{ i }}{% render 'break' %}{{ i }}{% endfor %}",
               files
             ) ==
               "112233"
    end

    test "increment is isolated between renders" do
      files = %{"incr" => "{% increment %}"}

      assert render_with_files("{% increment %}{% increment %}{% render 'incr' %}", files) ==
               "010"
    end

    test "decrement is isolated between renders" do
      files = %{"decr" => "{% decrement %}"}

      assert render_with_files("{% decrement %}{% decrement %}{% render 'decr' %}", files) ==
               "-1-2-1"
    end
  end

  describe "render with" do
    test "render tag with" do
      files = %{"product" => "Product: {{ product.title }}"}

      assert render_with_files("{% render 'product' with products[0] %}", files, %{
               "products" => [%{"title" => "Draft 151cm"}, %{"title" => "Element 155cm"}]
             }) == "Product: Draft 151cm"
    end

    test "render tag with alias" do
      files = %{"product_alias" => "Product: {{ product.title }}"}

      assert render_with_files(
               "{% render 'product_alias' with products[0] as product %}",
               files,
               %{
                 "products" => [%{"title" => "Draft 151cm"}, %{"title" => "Element 155cm"}]
               }
             ) == "Product: Draft 151cm"
    end
  end

  describe "render for" do
    test "render tag with for" do
      files = %{"product" => "Product: {{ product.title }} "}

      assert render_with_files("{% render 'product' for products %}", files, %{
               "products" => [%{"title" => "Draft 151cm"}, %{"title" => "Element 155cm"}]
             }) == "Product: Draft 151cm Product: Element 155cm"
    end

    test "render tag with for and alias" do
      files = %{"product_alias" => "Product: {{ product.title }} "}

      assert render_with_files("{% render 'product_alias' for products as product %}", files, %{
               "products" => [%{"title" => "Draft 151cm"}, %{"title" => "Element 155cm"}]
             }) == "Product: Draft 151cm Product: Element 155cm"
    end

    test "render tag with forloop variable" do
      files = %{
        "product" =>
          "Product: {{ product.title }} {% if forloop.first %}first{% endif %} {% if forloop.last %}last{% endif %} index:{{ forloop.index }} "
      }

      assert render_with_files("{% render 'product' for products %}", files, %{
               "products" => [%{"title" => "Draft 151cm"}, %{"title" => "Element 155cm"}]
             }) == "Product: Draft 151cm first  index:1 Product: Element 155cm  last index:2"
    end
  end
end
