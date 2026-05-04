defmodule Liquex.Parser.Diagnostic do
  @moduledoc false

  # Post-failure diagnostic pass. NimbleParsec's `choice/1` has no commit
  # primitive, so when a tag-name typo causes every alternative to backtrack,
  # the eventual failure surfaces at the end of the document with reason
  # "expected end of string". This module inspects the template at the
  # failure offset and, where it can, replaces that generic reason with a
  # message that points at the actual mistake.
  #
  # Each rule returns either nil (no match) or {reason, line, column}.
  # Rules are tried in order; the first match wins.

  @block_openers ~w(if for case unless capture tablerow raw comment)
  @block_closers %{
    "endif" => "if",
    "endfor" => "for",
    "endcase" => "case",
    "endunless" => "unless",
    "endcapture" => "capture",
    "endtablerow" => "tablerow",
    "endraw" => "raw",
    "endcomment" => "comment"
  }
  @simple_tags ~w(assign break continue cycle echo include increment decrement
                  liquid render elsif else when)

  @spec known_tags() :: [String.t()]
  def known_tags do
    @block_openers ++ Map.keys(@block_closers) ++ @simple_tags
  end

  @spec diagnose(String.t(), String.t(), non_neg_integer(), pos_integer(), pos_integer(), term()) ::
          {String.t(), pos_integer(), pos_integer()}
  def diagnose(template, rest, offset, fallback_line, fallback_col, fallback_reason) do
    rules = [
      &orphan_close/3,
      &unclosed_raw/3,
      &unknown_tag/3,
      &unclosed_open/3,
      &unclosed_string/3,
      &smart_quotes/3,
      &block_balance/3
    ]

    Enum.find_value(rules, fn rule -> rule.(template, rest, offset) end) ||
      {format_fallback(fallback_reason), fallback_line, fallback_col}
  end

  defp format_fallback(reason) when is_binary(reason), do: reason
  defp format_fallback(reason), do: inspect(reason)

  # ── Rule: orphan close ────────────────────────────────────────────────────
  # rest starts with %} or }} and the matching opener is missing in everything
  # parsed so far.

  defp orphan_close(template, "%}" <> _, offset),
    do: orphan_close_msg(template, offset, "%}", "{%")

  defp orphan_close(template, "-%}" <> _, offset),
    do: orphan_close_msg(template, offset, "-%}", "{%")

  defp orphan_close(template, "}}" <> _, offset),
    do: orphan_close_msg(template, offset, "}}", "{{")

  defp orphan_close(template, "-}}" <> _, offset),
    do: orphan_close_msg(template, offset, "-}}", "{{")

  defp orphan_close(_, _, _), do: nil

  defp orphan_close_msg(template, offset, close, open) do
    {line, col} = position_at(template, offset)
    {"unexpected `#{close}` (no matching `#{open}`)", line, col}
  end

  # ── Rule: unclosed {% raw %} ─────────────────────────────────────────────

  defp unclosed_raw(template, _rest, _offset) do
    opens = scan_offsets(template, ~r/\{%-?\s*raw\s*-?%\}/)
    closes = scan_offsets(template, ~r/\{%-?\s*endraw\s*-?%\}/)

    if length(opens) > length(closes) do
      unmatched = Enum.at(opens, length(closes))
      {line, col} = position_at(template, unmatched)

      {"unclosed `{% raw %}` (expected `{% endraw %}`)", line, col}
    end
  end

  # Return byte offsets for every match.
  defp scan_offsets(template, regex) do
    regex
    |> Regex.scan(template, return: :index)
    |> Enum.map(fn [{start, _len} | _] -> start end)
  end

  # ── Rule: unknown tag name ───────────────────────────────────────────────

  defp unknown_tag(template, rest, offset) do
    with {:ok, name} <- extract_tag_name_at(rest),
         false <- name in known_tags() do
      {line, col} = position_at(template, offset)
      hint = did_you_mean(name, known_tags())
      {"unknown tag `#{name}`#{hint}", line, col}
    else
      _ -> nil
    end
  end

  defp extract_tag_name_at("{%-" <> rest), do: extract_tag_name(rest)
  defp extract_tag_name_at("{%" <> rest), do: extract_tag_name(rest)
  defp extract_tag_name_at(_), do: :error

  defp extract_tag_name(rest) do
    rest = String.trim_leading(rest)

    case Regex.run(~r/\A([A-Za-z_][A-Za-z0-9_]*)/, rest) do
      [_, name] -> {:ok, name}
      _ -> :error
    end
  end

  defp did_you_mean(name, candidates) do
    {best, score} =
      Enum.reduce(candidates, {nil, 0.0}, fn candidate, {best, best_score} ->
        s = String.jaro_distance(name, candidate)
        if s > best_score, do: {candidate, s}, else: {best, best_score}
      end)

    cond do
      best && score >= 0.75 -> " (did you mean `#{best}`?)"
      true -> ""
    end
  end

  # ── Rule: unclosed open ──────────────────────────────────────────────────

  defp unclosed_open(template, "{%-" <> _, offset),
    do: unclosed_open_msg(template, offset, "{%", "%}")

  defp unclosed_open(template, "{%" <> _, offset),
    do: unclosed_open_msg(template, offset, "{%", "%}")

  defp unclosed_open(template, "{{-" <> _, offset),
    do: unclosed_open_msg(template, offset, "{{", "}}")

  defp unclosed_open(template, "{{" <> _, offset),
    do: unclosed_open_msg(template, offset, "{{", "}}")

  defp unclosed_open(_, _, _), do: nil

  defp unclosed_open_msg(template, offset, open, close) do
    rest = binary_part(template, offset, byte_size(template) - offset)

    if has_close_ahead?(rest, close) do
      nil
    else
      {line, col} = position_at(template, offset)
      {"unclosed `#{open}` (expected `#{close}`)", line, col}
    end
  end

  defp has_close_ahead?(rest, close) do
    String.contains?(rest, close) or String.contains?(rest, "-" <> close)
  end

  # ── Rule: unclosed string literal ────────────────────────────────────────

  defp unclosed_string(template, rest, offset) do
    with true <- String.starts_with?(rest, "{%") or String.starts_with?(rest, "{{"),
         {tag_body, _close} <- extract_tag_body(rest),
         {qchar, _} <- find_unclosed_quote(tag_body) do
      {line, col} = position_at(template, offset)
      {"unclosed #{quote_label(qchar)} string in tag", line, col}
    else
      _ -> nil
    end
  end

  defp extract_tag_body(rest) do
    case Regex.run(~r/\A\{[%{]-?(.*?)-?[%}]\}/s, rest, return: :index) do
      [{_full_start, full_len}, {body_start, body_len}] ->
        body = binary_part(rest, body_start, body_len)
        close_at = full_len
        {body, close_at}

      _ ->
        :error
    end
  end

  # Walk the body counting quotes; if we exit while inside a string, that's
  # the unclosed quote.
  defp find_unclosed_quote(body), do: walk_quotes(body, nil, 0)

  defp walk_quotes("", nil, _pos), do: nil
  defp walk_quotes("", q, pos), do: {q, pos}

  defp walk_quotes(<<?\\, _::utf8, rest::binary>>, q, pos) when q in [?\", ?\'],
    do: walk_quotes(rest, q, pos + 2)

  defp walk_quotes(<<?\", rest::binary>>, nil, pos), do: walk_quotes(rest, ?\", pos + 1)
  defp walk_quotes(<<?\", rest::binary>>, ?\", pos), do: walk_quotes(rest, nil, pos + 1)
  defp walk_quotes(<<?\', rest::binary>>, nil, pos), do: walk_quotes(rest, ?\', pos + 1)
  defp walk_quotes(<<?\', rest::binary>>, ?\', pos), do: walk_quotes(rest, nil, pos + 1)
  defp walk_quotes(<<_::utf8, rest::binary>>, q, pos), do: walk_quotes(rest, q, pos + 1)

  defp quote_label(?\"), do: "double-quoted"
  defp quote_label(?\'), do: "single-quoted"

  # ── Rule: smart quotes ───────────────────────────────────────────────────

  defp smart_quotes(template, _rest, _offset) do
    case Regex.run(~r/[\x{201C}\x{201D}\x{2018}\x{2019}]/u, template, return: :index) do
      [{pos, _}] ->
        {line, col} = position_at(template, pos)

        {"smart quote detected — replace with a straight quote (`\"` or `'`)", line, col}

      _ ->
        nil
    end
  end

  # ── Rule: block balance ──────────────────────────────────────────────────

  defp block_balance(template, _rest, _offset) do
    case scan_blocks(template) do
      {:unclosed, name, line, col} ->
        end_name = "end" <> name

        {"unclosed `{% #{name} %}` (expected `{% #{end_name} %}`)", line, col}

      {:mismatch, found, expected, opener_line, found_line, found_col} ->
        reason =
          "unexpected `{% #{found} %}` " <>
            "(expected `{% #{expected} %}` to close block opened at line #{opener_line})"

        {reason, found_line, found_col}

      {:typo_close, found, expected, opener_line, found_line, found_col} ->
        reason =
          "unknown tag `#{found}` (did you mean `#{expected}`? " <>
            "block opened at line #{opener_line})"

        {reason, found_line, found_col}

      {:orphan, found, line, col} ->
        {"unexpected `{% #{found} %}` (no matching opener)", line, col}

      :ok ->
        nil
    end
  end

  # Walk every {% ... %} in order, tracking a stack of open block tags. Skips
  # bodies of `raw` and `comment` since their content is not interpreted.
  defp scan_blocks(template) do
    tags = scan_all(template, ~r/\{%-?\s*([A-Za-z_][A-Za-z0-9_]*)\s*[^%]*?-?%\}/)
    walk_blocks(tags, [])
  end

  defp walk_blocks([], []), do: :ok

  defp walk_blocks([], [{name, line, col} | _]),
    do: {:unclosed, name, line, col}

  defp walk_blocks([{name, line, col, _offset} | rest], stack) do
    cond do
      # Inside a raw or comment block, ignore everything until the matching end.
      stack_top_is?(stack, "raw") and name != "endraw" ->
        walk_blocks(rest, stack)

      stack_top_is?(stack, "comment") and name != "endcomment" ->
        walk_blocks(rest, stack)

      name in @block_openers ->
        walk_blocks(rest, [{name, line, col} | stack])

      Map.has_key?(@block_closers, name) ->
        expected = Map.fetch!(@block_closers, name)

        case stack do
          [{^expected, _, _} | rest_stack] ->
            walk_blocks(rest, rest_stack)

          [{other, opener_line, _opener_col} | _] ->
            {:mismatch, name, "end" <> other, opener_line, line, col}

          [] ->
            {:orphan, name, line, col}
        end

      true ->
        # If the tag name looks like a typo'd closer for whatever block we're
        # currently inside, surface it as a typo rather than silently ignoring.
        case typo_close_for(name, stack) do
          {expected_close, opener_line} ->
            {:typo_close, name, expected_close, opener_line, line, col}

          nil ->
            walk_blocks(rest, stack)
        end
    end
  end

  defp typo_close_for(name, [{opener, opener_line, _} | _])
       when is_binary(name) and is_binary(opener) do
    expected = "end" <> opener

    if String.starts_with?(name, "end") and name != expected and
         String.jaro_distance(name, expected) >= 0.8 do
      {expected, opener_line}
    end
  end

  defp typo_close_for(_, _), do: nil

  defp stack_top_is?([{name, _, _} | _], name), do: true
  defp stack_top_is?(_, _), do: false

  # ── Helpers ──────────────────────────────────────────────────────────────

  # Find every match of regex in template; return [{name, line, col, byte_offset}].
  defp scan_all(template, regex) do
    Regex.scan(regex, template, return: :index, capture: :all)
    |> Enum.map(fn matches ->
      [{full_start, _full_len}, {name_start, name_len}] = matches
      name = binary_part(template, name_start, name_len)
      {line, col} = position_at(template, full_start)
      {name, line, col, full_start}
    end)
  end

  # Convert a byte offset into a {line, column} pair (1-based).
  @spec position_at(String.t(), non_neg_integer()) :: {pos_integer(), pos_integer()}
  def position_at(template, offset) do
    offset = min(offset, byte_size(template))
    prefix = binary_part(template, 0, offset)

    line = 1 + count_newlines(prefix)

    last_nl =
      case :binary.matches(prefix, "\n") do
        [] -> -1
        positions -> positions |> List.last() |> elem(0)
      end

    col = byte_size(prefix) - last_nl

    {line, col}
  end

  defp count_newlines(binary) do
    binary
    |> :binary.matches("\n")
    |> length()
  end
end
