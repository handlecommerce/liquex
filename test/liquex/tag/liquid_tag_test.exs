defmodule Liquex.Tag.LiquidTagTest do
  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  describe "parse" do
    test "handles recursive liquid tags" do
      assert_parse(
        "{% liquid liquid echo 'hello' %}",
        [
          {
            {:tag, Liquex.Tag.LiquidTag},
            [
              contents: [
                {{:tag, Liquex.Tag.LiquidTag},
                 [contents: [{{:tag, Liquex.Tag.EchoTag}, [literal: "hello", filters: []]}]]}
              ]
            ]
          }
        ]
      )
    end

    test "handles recursive liquid tags at depth higher than 2" do
      assert_parse(
        "{% liquid liquid liquid liquid liquid echo 'hello' %}",
        [
          {{:tag, Liquex.Tag.LiquidTag},
           [
             contents: [
               {{:tag, Liquex.Tag.LiquidTag},
                [
                  contents: [
                    {{:tag, Liquex.Tag.LiquidTag},
                     [
                       contents: [
                         {{:tag, Liquex.Tag.LiquidTag},
                          [
                            contents: [
                              {{:tag, Liquex.Tag.LiquidTag},
                               [
                                 contents: [
                                   {{:tag, Liquex.Tag.EchoTag}, [literal: "hello", filters: []]}
                                 ]
                               ]}
                            ]
                          ]}
                       ]
                     ]}
                  ]
                ]}
             ]
           ]}
        ]
      )
    end
  end

  describe "render" do
    # Most of these tests are done in the individual tag tests. This is only
    # focusing on recursive liquid tags.
    test "renders tag" do
      assert render("""
             {% liquid liquid liquid liquid echo 'hello world' %}
             """) == "hello world"
    end
  end
end
