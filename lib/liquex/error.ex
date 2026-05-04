defmodule Liquex.Error do
  @moduledoc """
  Exception raised for parse and render failures.

  In addition to `:message`, the struct carries structured fields that are
  useful for tooling:

    * `:reason`  — short reason without surrounding context
    * `:line`    — 1-based line number where the failure was detected
    * `:column`  — 1-based column number
    * `:excerpt` — multi-line snippet of the source around the failure with a caret
    * `:hint`    — optional follow-up suggestion (e.g. "did you mean `if`?")
    * `:kind`    — `:parse` or `:render`
  """

  defexception [:message, :reason, :line, :column, :excerpt, :hint, :kind]

  @type t :: %__MODULE__{
          message: String.t() | nil,
          reason: String.t() | nil,
          line: pos_integer() | nil,
          column: pos_integer() | nil,
          excerpt: String.t() | nil,
          hint: String.t() | nil,
          kind: :parse | :render | nil
        }

  @doc """
  Build a `Liquex.Error` from a parse failure.
  """
  @spec from_parser(String.t(), String.t(), pos_integer(), pos_integer()) :: t()
  def from_parser(template, reason, line, column) do
    excerpt = build_excerpt(template, line, column)

    %__MODULE__{
      message: format(:parse, reason, line, column, excerpt),
      reason: reason,
      line: line,
      column: column,
      excerpt: excerpt,
      kind: :parse
    }
  end

  @doc """
  Build a render-time `Liquex.Error` from a free-form message.
  """
  @spec render_error(String.t()) :: t()
  def render_error(message) do
    %__MODULE__{message: message, reason: message, kind: :render}
  end

  defp format(:parse, reason, line, column, excerpt) do
    """
    Liquid parse error at line #{line}, column #{column}: #{reason}

    #{excerpt}\
    """
  end

  defp build_excerpt(template, line, column) when is_integer(line) and is_integer(column) do
    lines = String.split(template, "\n")
    total = length(lines)

    from = max(line - 1, 1)
    to = min(line + 1, total)

    gutter_width =
      to
      |> Integer.to_string()
      |> String.length()

    rendered_lines =
      from..to
      |> Enum.map(fn n ->
        body = Enum.at(lines, n - 1, "")
        gutter = n |> Integer.to_string() |> String.pad_leading(gutter_width)
        "  #{gutter} | #{body}"
      end)

    caret_pad =
      String.duplicate(" ", gutter_width) <>
        "   " <> String.duplicate(" ", max(column - 1, 0))

    rendered =
      rendered_lines
      |> insert_caret_after(line, from, to, caret_pad)
      |> Enum.join("\n")

    rendered
  end

  defp build_excerpt(_, _, _), do: nil

  defp insert_caret_after(lines, target_line, from, _to, caret_pad) do
    target_idx = target_line - from

    {head, tail} = Enum.split(lines, target_idx + 1)
    head ++ ["  " <> caret_pad <> "^"] ++ tail
  end
end
