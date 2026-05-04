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

    test "block opened but never closed shows the offending tag's markup" do
      assert {:error, reason, line} = Liquex.parse("{% if x %}\n  body\n")
      assert reason =~ "unclosed `{% if x %}`"
      assert reason =~ "expected `{% endif %}`"
      # Diagnostic points at the opener
      assert line == 1
    end

    test "block close mismatch shows the unexpected tag's markup" do
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

    test "unclosed single-quoted string in tag" do
      template = ~s({% if x == 'hello %}body{% endif %})
      assert {:error, reason, _line} = Liquex.parse(template)
      assert reason =~ "unclosed single-quoted string"
    end

    test "whitespace-trim opener `{%-` is also detected when unclosed" do
      assert {:error, reason, _} = Liquex.parse("{%- if x")
      assert reason =~ "unclosed `{%`"
    end

    test "whitespace-trim variable opener `{{-` is also detected when unclosed" do
      assert {:error, reason, _} = Liquex.parse("{{- x")
      assert reason =~ "unclosed `{{`"
    end

    test "valid comment block parses without diagnostic interference" do
      # Liquex parses comment bodies (unlike Ruby Liquid's opaque comments), so
      # use a body that itself parses.
      assert {:ok, _} = Liquex.parse("{% comment %}just text{% endcomment %}")
    end

    test "tags inside `{% raw %}` don't trigger phantom unclosed reports" do
      assert {:ok, _} = Liquex.parse("{% raw %}{% if x %}{% endraw %}")
    end

    test "tag opener with no name falls through to a generic diagnosis" do
      # `{% %}` produces a parse error but doesn't satisfy unknown_tag (no name)
      # or any other specific rule — should fall back to a NimbleParsec reason.
      assert {:error, reason, _} = Liquex.parse("{% %}")
      assert is_binary(reason)
    end

    test "escaped quotes inside a tag string aren't misdiagnosed as unclosed" do
      # Liquex's expression grammar doesn't accept escaped quotes, so this
      # template fails to parse. What we're verifying here is that our quote
      # walker recognizes the escape and does NOT report "unclosed string"
      # (it would if we naively counted quotes).
      assert {:error, reason, _} = Liquex.parse(~s({% if x == "he\\"llo" %}body{% endif %}))
      refute reason =~ "unclosed double-quoted"
    end

    test "balanced template with bad inner expression falls back to NimbleParsec reason" do
      # `{{ ... }}` is balanced, so block_balance returns :ok and we surface
      # whatever NimbleParsec said.
      assert {:error, reason, _} = Liquex.parse("{{ x ! }}")
      assert is_binary(reason)
      assert reason != ""
    end

    test "long tag markup is truncated in the error message" do
      # 90+ char if expression so it exceeds the 60-char cap.
      long_expr =
        "{% if user.role == 'admin' and user.active and (user.team == 'engineering' or user.team == 'product') %}body"

      assert {:error, reason, _} = Liquex.parse(long_expr)
      assert reason =~ "unclosed"
      assert reason =~ "..."
      # Ensure the embedded snippet stays under the cap (60 chars + ellipsis).
      assert String.length(reason) < 200
    end

    test "multi-line tag markup is collapsed to one line in the error" do
      template = "{% if x ==\n   y or z ==\n   w %}body"

      assert {:error, reason, _} = Liquex.parse(template)
      refute reason =~ "\n", "embedded markup should be flattened"
    end

    test "deeply nested matching blocks parse successfully" do
      template = """
      {% for x in xs %}
        {% if x %}
          {% case y %}{% when 1 %}one{% endcase %}
        {% endif %}
      {% endfor %}
      """

      assert {:ok, _} = Liquex.parse(template)
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
