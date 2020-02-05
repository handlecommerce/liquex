defmodule Liquex.Parser.LiteralTest do
  use ExUnit.Case

  test "boolean" do
    assert_parse("{{ true }}", object: [literal: true, filters: []])
    assert_parse("{{ false }}", object: [literal: false, filters: []])
  end

  test "integer" do
    assert_parse("{{ 123 }}", object: [literal: 123, filters: []])
    assert_parse("{{ -123 }}", object: [literal: -123, filters: []])
  end

  test "float" do
    assert_parse("{{ 123.45 }}", object: [literal: 123.45, filters: []])
    assert_parse("{{ -123.45 }}", object: [literal: -123.45, filters: []])
  end

  test "float with exponent" do
    assert_parse("{{ 123.45e2 }}", object: [literal: 12345.0, filters: []])
  end

  test "quoted_string" do
    assert_parse("{{ \"Hello World!\" }}", object: [literal: "Hello World!", filters: []])
    assert_parse("{{ 'Hello World!' }}", object: [literal: "Hello World!", filters: []])
  end

  def assert_parse(doc, match) do
    assert {:ok, ^match, "", _, _, _} = Liquex.Parser.parse(doc)
  end
end
