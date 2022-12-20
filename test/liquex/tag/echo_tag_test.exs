defmodule Liquex.Tag.EchoTagTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  alias Liquex.Context

  describe "parse" do
    test "handles simple object" do
      assert_parse(
        "{% echo true %}",
        [
          {{:tag, Liquex.Tag.EchoTag}, [literal: true, filters: []]}
        ]
      )
    end

    test "handles simple filter" do
      assert_parse(
        "{% echo true | not %}",
        [
          {{:tag, Liquex.Tag.EchoTag},
           [literal: true, filters: [filter: ["not", {:arguments, []}]]]}
        ]
      )
    end

    test "parses filter with single argument" do
      assert_parse(
        "{% echo 123.45 | money: 'USD' %}",
        [
          {{:tag, Liquex.Tag.EchoTag},
           [literal: 123.45, filters: [filter: ["money", {:arguments, [literal: "USD"]}]]]}
        ]
      )
    end

    test "parses filter with multiple arguments" do
      assert_parse(
        "{% echo 123.45 | money: 'USD', format %}",
        [
          {
            {:tag, Liquex.Tag.EchoTag},
            [
              literal: 123.45,
              filters: [filter: ["money", {:arguments, [literal: "USD", field: [key: "format"]]}]]
            ]
          }
        ]
      )
    end

    test "parses filter with key/value arguments" do
      assert_parse(
        "{% echo product | img_url: '400x400', crop: 'bottom' %}",
        [
          {
            {:tag, Liquex.Tag.EchoTag},
            [
              field: [key: "product"],
              filters: [
                filter: [
                  "img_url",
                  {:arguments, [literal: "400x400", keyword: ["crop", {:literal, "bottom"}]]}
                ]
              ]
            ]
          }
        ]
      )
    end

    test "parses filter with key/value arguments as first argument" do
      assert_parse(
        "{% echo product | img_url: crop: 'bottom' %}",
        [
          {
            {:tag, Liquex.Tag.EchoTag},
            [
              field: [key: "product"],
              filters: [
                filter: ["img_url", {:arguments, [keyword: ["crop", {:literal, "bottom"}]]}]
              ]
            ]
          }
        ]
      )
    end

    test "parses multiple filters" do
      assert_parse(
        "{% echo 'adam!' | capitalize | prepend: 'Hello ' %}",
        [
          {
            {:tag, Liquex.Tag.EchoTag},
            [
              literal: "adam!",
              filters: [
                filter: ["capitalize", {:arguments, []}],
                filter: ["prepend", {:arguments, [literal: "Hello "]}]
              ]
            ]
          }
        ]
      )
    end
  end

  describe "render" do
    test "simple objects" do
      assert "5" == render("{% echo 5 %}")
      assert "5" == render("{% liquid echo 5 %}")
      assert "Hello" == render("{% echo 'Hello' %}")
      assert "Hello" == render("{% liquid echo 'Hello' %}")
      assert "true" == render("{% echo true %}")
      assert "true" == render("{% liquid echo true %}")
      assert "" == render("{% echo nil %}")
      assert "" == render("{% liquid echo nil %}")
      assert "55" == render("{% liquid echo 5\necho 5 %}")
    end

    test "simple fields" do
      context =
        Context.new(%{
          "a" => "hello",
          "b" => %{"c" => 1}
        })

      assert "hello" == render("{% echo a %}", context)
      assert "1" == render("{% echo b.c %}", context)
    end

    test "list access to object fields" do
      context =
        Context.new(%{
          "a" => ["b", ["c", "d"]]
        })

      assert "bcd" == render("{% echo a %}", context)
      assert "b" == render("{% echo a[0] %}", context)
      assert "cd" == render("{% echo a[1] %}", context)
      assert "c" == render("{% echo a[1][0] %}", context)
      assert "" == render("{% echo a[2] %}", context)
    end

    test "wrong access to object and list fields" do
      context =
        Context.new(%{
          "b" => %{"c" => 1}
        })

      assert "" == render("{% echo b[0] %}", context)
    end

    test "removes tail whitespace" do
      assert "Hello" == render("{% echo 'Hello' -%} ")
    end

    test "removes leading whitespace" do
      assert "Hello" == render(" {%- echo 'Hello' %}")
    end
  end

  describe "render with filter" do
    test "abs" do
      assert "5" == render("{% echo -5 | abs %}")
      assert "5" == render("{% echo -5 | abs | abs %}")
    end

    test "invalid filter" do
      assert "-5" == render("{% echo -5 | bad_filter %}")
    end
  end

  describe "dynamic fields" do
    test "simple new field" do
      context = Context.new(%{"message" => fn _ -> "hello world" end})
      assert "hello world" == render("{% echo message %}", context)
    end

    test "dynamic field on parent object" do
      context =
        Context.new(%{
          "message" => %{
            "value" => "Hello World",
            "calculated_value" => fn %{"value" => value} -> value end
          }
        })

      assert "Hello World" == render("{% echo message.calculated_value %}", context)
    end
  end

  describe "square brackets object access" do
    test "simple field name" do
      context =
        Context.new(%{
          "message" => %{"key" => "Hello World"}
        })

      assert "Hello World" == render("{% echo message['key'] %}", context)
      assert "Hello World" == render("{% echo message[\"key\"] %}", context)
    end

    test "field name from context" do
      context =
        Context.new(%{
          "keyvar" => "key",
          "message" => %{
            "key" => "Hello World"
          }
        })

      assert "Hello World" == render("{% echo message[keyvar] %}", context)
    end

    test "field name from variable" do
      context =
        Context.new(%{
          "message" => %{
            "map" => %{"key" => "Hello World"}
          }
        })

      assert "Hello World" ==
               render(
                 "{% assign mapvar = \"map\" %}{% assign keyvar = \"key\" %}{% echo message[mapvar][keyvar] %}",
                 context
               )
    end
  end
end
