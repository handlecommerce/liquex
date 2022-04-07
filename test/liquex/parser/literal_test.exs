defmodule Liquex.Parser.LiteralTest do
  @moduledoc false

  use ExUnit.Case, async: true
  import Liquex.TestHelpers

  test "boolean" do
    assert_parse("{{ true }}", [{{:tag, Liquex.Tag.ObjectTag}, [literal: true, filters: []]}])
    assert_parse("{{ false }}", [{{:tag, Liquex.Tag.ObjectTag}, [literal: false, filters: []]}])
  end

  test "integer" do
    assert_parse("{{ 123 }}", [{{:tag, Liquex.Tag.ObjectTag}, [literal: 123, filters: []]}])
    assert_parse("{{ -123 }}", [{{:tag, Liquex.Tag.ObjectTag}, [literal: -123, filters: []]}])
  end

  test "float" do
    assert_parse("{{ 123.45 }}", [{{:tag, Liquex.Tag.ObjectTag}, [literal: 123.45, filters: []]}])

    assert_parse("{{ -123.45 }}", [
      {{:tag, Liquex.Tag.ObjectTag}, [literal: -123.45, filters: []]}
    ])
  end

  test "float with exponent" do
    assert_parse("{{ 123.45e2 }}", [
      {{:tag, Liquex.Tag.ObjectTag}, [literal: 12345.0, filters: []]}
    ])
  end

  test "quoted_string" do
    assert_parse("{{ \"Hello World!\" }}", [
      {{:tag, Liquex.Tag.ObjectTag}, [literal: "Hello World!", filters: []]}
    ])

    assert_parse("{{ 'Hello World!' }}", [
      {{:tag, Liquex.Tag.ObjectTag}, [literal: "Hello World!", filters: []]}
    ])
  end
end
