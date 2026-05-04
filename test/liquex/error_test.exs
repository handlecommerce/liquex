defmodule Liquex.ErrorTest do
  use ExUnit.Case, async: true

  describe "from_parser/4 builds a usable struct" do
    test "populates structured fields and a formatted message" do
      err = Liquex.Error.from_parser("hello world", "boom", 1, 1)

      assert err.kind == :parse
      assert err.line == 1
      assert err.column == 1
      assert err.reason == "boom"
      assert err.message =~ "Liquid parse error at line 1, column 1: boom"
      assert err.excerpt =~ "  1 | hello world"
      assert err.excerpt =~ "^"
    end

    test "excerpt around a middle line shows context above and below" do
      template = "line1\nline2\nline3\nline4\nline5"
      err = Liquex.Error.from_parser(template, "x", 3, 2)

      assert err.excerpt =~ "  2 | line2"
      assert err.excerpt =~ "  3 | line3"
      assert err.excerpt =~ "  4 | line4"
      refute err.excerpt =~ "line1"
      refute err.excerpt =~ "line5"
    end

    test "excerpt at line 1 doesn't underflow" do
      err = Liquex.Error.from_parser("only line", "x", 1, 1)
      assert err.excerpt =~ "  1 | only line"
    end

    test "excerpt at the last line doesn't overflow" do
      template = "first\nlast"
      err = Liquex.Error.from_parser(template, "x", 2, 1)
      assert err.excerpt =~ "  1 | first"
      assert err.excerpt =~ "  2 | last"
    end

    test "multi-digit line numbers align the gutter" do
      template = Enum.map_join(1..12, "\n", &"line #{&1}")
      err = Liquex.Error.from_parser(template, "x", 11, 1)

      # Gutter pads to 2 chars wide for line 12, so line 10 reads "  10 | "
      assert err.excerpt =~ "  10 | line 10"
      assert err.excerpt =~ "  11 | line 11"
      assert err.excerpt =~ "  12 | line 12"
    end

    test "caret position reflects the column" do
      err = Liquex.Error.from_parser("abcdefg", "x", 1, 4)
      caret_line = err.excerpt |> String.split("\n") |> Enum.find(&String.contains?(&1, "^"))

      # The visible "  1 | " gutter is 6 chars; column 4 means caret index = 6 + 3.
      assert String.length(caret_line) - 1 == 6 + (4 - 1)
    end
  end

  describe "render_error/1" do
    test "returns a render-kind struct with the message preserved" do
      err = Liquex.Error.render_error("nope")
      assert err.kind == :render
      assert err.message == "nope"
      assert err.reason == "nope"
    end
  end

  describe "Diagnostic.diagnose/6 fallback path" do
    test "returns NimbleParsec's reason verbatim when no rule fires" do
      # Direct call so we exercise the fallback explicitly.
      assert {"the reason", 5, 7} =
               Liquex.Parser.Diagnostic.diagnose("plain text", "", 10, 5, 7, "the reason")
    end

    test "stringifies non-binary fallback reasons defensively" do
      assert {reason, _, _} =
               Liquex.Parser.Diagnostic.diagnose("plain text", "", 0, 1, 1, {:nimble, :weird})

      assert reason =~ "nimble"
    end
  end

  describe "as an exception" do
    test "raises with the formatted message" do
      err = Liquex.Error.from_parser("x", "boom", 1, 1)

      assert_raise Liquex.Error, ~r/Liquid parse error at line 1, column 1/, fn ->
        raise err
      end
    end
  end
end
