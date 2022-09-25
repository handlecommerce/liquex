defmodule Liquex.Tag.ObjectTagTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  alias Liquex.Context

  describe "parse" do
    test "handles simple filter" do
      assert_parse(
        "{{ true | not }}",
        [
          {{:tag, Liquex.Tag.ObjectTag},
           [literal: true, filters: [filter: ["not", {:arguments, []}]]]}
        ]
      )
    end

    test "parses filter with single argument" do
      assert_parse(
        "{{ 123.45 | money: 'USD' }}",
        [
          {{:tag, Liquex.Tag.ObjectTag},
           [literal: 123.45, filters: [filter: ["money", {:arguments, [literal: "USD"]}]]]}
        ]
      )
    end

    test "parses filter with multiple arguments" do
      assert_parse(
        "{{ 123.45 | money: 'USD', format }}",
        [
          {
            {:tag, Liquex.Tag.ObjectTag},
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
        "{{ product | img_url: '400x400', crop: 'bottom' }}",
        [
          {
            {:tag, Liquex.Tag.ObjectTag},
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
        "{{ product | img_url: crop: 'bottom' }}",
        [
          {
            {:tag, Liquex.Tag.ObjectTag},
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
        "{{ 'adam!' | capitalize | prepend: 'Hello ' }}",
        [
          {
            {:tag, Liquex.Tag.ObjectTag},
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
      assert "5" == render("{{ 5 }}")
      assert "Hello" == render("{{ 'Hello' }}")
      assert "true" == render("{{ true }}")
      assert "" == render("{{ nil }}")
    end

    test "simple fields" do
      context =
        Context.new(%{
          "a" => "hello",
          "b" => %{"c" => 1}
        })

      assert "hello" == render("{{ a }}", context)
      assert "1" == render("{{ b.c }}", context)
    end

    test "list access to object fields" do
      context =
        Context.new(%{
          "a" => ["b", ["c", "d"]]
        })

      assert "bcd" == render("{{ a }}", context)
      assert "b" == render("{{ a[0] }}", context)
      assert "cd" == render("{{ a[1] }}", context)
      assert "c" == render("{{ a[1][0] }}", context)
      assert "" == render("{{ a[2] }}", context)
    end

    test "wrong access to object and list fields" do
      context =
        Context.new(%{
          "b" => %{"c" => 1}
        })

      assert "" == render("{{ b[0] }}", context)
    end

    test "removes tail whitespace" do
      assert "Hello" == render("{{ 'Hello' -}} ")
    end

    test "removes leading whitespace" do
      assert "Hello" == render(" {{- 'Hello' }}")
    end
  end

  describe "render with filter" do
    test "abs" do
      assert "5" == render("{{ -5 | abs }}")
      assert "5" == render("{{ -5 | abs | abs }}")
    end

    test "invalid filter" do
      assert "-5" == render("{{ -5 | bad_filter }}")
    end
  end

  describe "dynamic fields" do
    test "simple new field" do
      context = Context.new(%{"message" => fn _ -> "hello world" end})
      assert "hello world" == render("{{ message }}", context)
    end

    test "dynamic field on parent object" do
      context =
        Context.new(%{
          "message" => %{
            "value" => "Hello World",
            "calculated_value" => fn %{"value" => value} -> value end
          }
        })

      assert "Hello World" == render("{{ message.calculated_value }}", context)
    end
  end

  describe "square brackets object access" do
    test "simple field name" do
      context =
        Context.new(%{
          "message" => %{"key" => "Hello World"}
        })

      assert "Hello World" == render("{{ message['key'] }}", context)
      assert "Hello World" == render("{{ message[\"key\"] }}", context)
    end

    test "field name from context" do
      context =
        Context.new(%{
          "keyvar" => "key",
          "message" => %{
            "key" => "Hello World"
          }
        })

      assert "Hello World" == render("{{ message[keyvar] }}", context)
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
                 "{% assign mapvar = \"map\" %}{% assign keyvar = \"key\" %}{{ message[mapvar][keyvar] }}",
                 context
               )
    end
  end
end
