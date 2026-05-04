defmodule Liquex.Parser.DiagnosticTest do
  use ExUnit.Case, async: true

  describe "Liquex.parse/2 returns diagnosed errors" do
    test "unknown tag with did-you-mean suggestion" do
      assert {:error, reason, line} = Liquex.parse("{% iff x %}{% endif %}")
      assert reason =~ "unknown tag `iff`"
      assert reason =~ "did you mean `if`?"
      assert line == 1
    end

    test "unknown tag without close suggestion when nothing matches well" do
      assert {:error, reason, _line} = Liquex.parse("{% qqxyzzy %}{% endqqxyzzy %}")
      assert reason =~ "unknown tag `qqxyzzy`"
      refute reason =~ "did you mean"
    end

    test "unclosed `{%` with no `%}` ahead" do
      assert {:error, reason, line} = Liquex.parse("{% if x")
      assert reason =~ "unclosed `{%`"
      assert reason =~ "expected `%}`"
      assert line == 1
    end

    test "unclosed `{{` with no `}}` ahead" do
      assert {:error, reason, line} = Liquex.parse("{{ unclosed")
      assert reason =~ "unclosed `{{`"
      assert reason =~ "expected `}}`"
      assert line == 1
    end

    test "block opened but never closed" do
      assert {:error, reason, line} = Liquex.parse("{% if x %}\n  body\n")
      assert reason =~ "unclosed `{% if %}`"
      assert reason =~ "expected `{% endif %}`"
      # Diagnostic points at the opener
      assert line == 1
    end

    test "block close mismatch references opener line" do
      template = "{% if x %}\n  {% for i in items %}\n  {% endif %}\n{% endfor %}"
      assert {:error, reason, line} = Liquex.parse(template)
      assert reason =~ "unexpected `{% endif %}`"
      assert reason =~ "expected `{% endfor %}`"
      assert reason =~ "opened at line 2"
      assert line == 3
    end

    test "typo'd closer suggests the right close and references opener line" do
      assert {:error, reason, line} = Liquex.parse("{% if x %}\nhello\n{% endfi %}")
      assert reason =~ "unknown tag `endfi`"
      assert reason =~ "did you mean `endif`?"
      assert reason =~ "opened at line 1"
      assert line == 3
    end

    test "orphan close without matching opener" do
      assert {:error, reason, line} = Liquex.parse("before {% endif %} after")
      assert reason =~ "unexpected `{% endif %}`"
      assert reason =~ "no matching opener"
      assert line == 1
    end

    test "unclosed raw block" do
      assert {:error, reason, line} = Liquex.parse("{% raw %}content")
      assert reason =~ "unclosed `{% raw %}`"
      assert reason =~ "expected `{% endraw %}`"
      assert line == 1
    end

    test "unclosed double-quoted string in tag" do
      template = ~s({% if x == "hello %}body{% endif %})
      assert {:error, reason, _line} = Liquex.parse(template)
      assert reason =~ "unclosed double-quoted string"
    end

    test "smart quote diagnosed when nothing else fires" do
      template = "{% if x == “hello” %}body{% endif %}"
      assert {:error, reason, _line} = Liquex.parse(template)
      assert reason =~ "smart quote"
    end

    test "multiline typo points at typo line, not document end" do
      assert {:error, reason, line} = Liquex.parse("Hello\n{% iff x %}\nworld\n{% endif %}")
      assert reason =~ "unknown tag `iff`"
      assert line == 2
    end

    test "valid templates still parse without diagnostic interference" do
      assert {:ok, _} = Liquex.parse("{% if x %}body{% endif %}")
      assert {:ok, _} = Liquex.parse("{{ x | upcase }}")
      assert {:ok, _} = Liquex.parse("plain text")
    end
  end

  describe "Liquex.parse!/2 raises a formatted Liquex.Error" do
    test "raises with structured fields populated" do
      err =
        try do
          Liquex.parse!("Hello\n{% iff x %}\nworld\n{% endif %}")
          flunk("expected raise")
        rescue
          e in Liquex.Error -> e
        end

      assert err.kind == :parse
      assert err.line == 2
      assert err.column == 1
      assert err.reason =~ "unknown tag `iff`"
      assert err.excerpt =~ "{% iff x %}"
      assert err.excerpt =~ "^"
      assert err.message =~ "Liquid parse error at line 2, column 1"
    end
  end
end
