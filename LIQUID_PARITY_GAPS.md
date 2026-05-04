# Liquid Parity Gaps

Known divergences between Liquex and the Ruby Liquid gem (Shopify's reference
implementation), as of v0.14.0. These are byte-for-byte differences in template
output or differences in error/crash behavior.

Priorities (rough): **High** = silent output differences or crashes on common
inputs. **Medium** = crashes on uncommon inputs Liquid handles. **Low** = rare
edge cases or differences in error surface only.

## Error modes

Ruby Liquid has two parser error modes selected via `Liquid::Template.parse(src,
error_mode: …)`:

- **`:lax`** (default) — silently swallows malformed Variable expressions. A
  template like `{{ 1 == 1 }}` parses by matching `1` as the value and
  dropping `== 1` as junk; `{{ 1abc }}` parses as an undefined-variable
  lookup and renders `""`. Production Liquid usage (Shopify themes, the
  default `Template.parse(src)` call) runs in lax mode.
- **`:strict`** — raises `Liquid::SyntaxError` on the same inputs.

Liquex doesn't expose a mode option and picks lax behavior as its target,
since lax matches what 99% of templates expect. Where Liquex currently
diverges from lax, those gaps are listed below as parser items. Strict-mode
behavior (raising domain-specific errors at parse time) is out of scope —
adding a mode option would be significant infrastructure for a niche
audience.

---

## Parser — crashes on inputs Liquid handles in lax mode

### 1. Numeric-prefix tokens that aren't valid numbers — Medium

`{{ 1e10 }}`, `{{ 1abc }}`, `{{ 0x10 }}`, `{{ 1_000 }}` raise `MatchError`.
Liquid (lax) silently treats them as undefined variable lookups → `""`.
Liquid (strict) raises `Liquid::SyntaxError`. We target lax.

**Why**: Liquex's literal parser matches a prefix (`int()`/`float()`) and leaves
the remainder unconsumed, then no other branch can parse what's left.

**Fix sketch**: After the literal/range/field choice, add a "consume any
identifier-ish junk and produce nil" fallback for tokens that start with a
digit but don't fully parse as a number. Or extend the field grammar to allow
identifiers starting with digits (Liquid's own behavior).

### 2. Comparison expressions in `{{ ... }}` — Medium

`{{ 1 == 1 }}` raises `MatchError`. Liquid (lax) swallows `== 1` via its
`Variable` parser and prints `"1"`. Liquid (strict) raises
`Liquid::SyntaxError`. We target lax.

**Why**: We applied the junk-swallow fix to `AssignTag.parse` but not to
`ObjectTag.parse`. Liquid uses the same `MarkupWithQuotedFragment` regex for
both.

**Fix sketch**: Lift the junk-between-value-and-filters parser out of
`AssignTag` and reuse it in `ObjectTag`.

### 3. Escaped single quote in single-quoted strings — Low

`'a\'b'` raises `MatchError`. Liquid handles the `\'` escape.

**Why**: `Liquex.Parser.Literal.quoted_string/0` matches `string("\\'")` for
single-quoted, but the surrounding template-tag parsing doesn't reach it
correctly. Needs investigation.

### 4. Structured syntax errors — Low

`{% nope %}` (unknown tag), `{% if true %}x` (unclosed) raise `MatchError` /
`Liquex.Error` instead of a structured `Liquid::SyntaxError` equivalent.
Downstream tooling that pattern-matches on exception types sees Elixir-native
exceptions instead of Liquex-domain ones.

**Fix sketch**: Wrap the NimbleParsec entry point so all parse failures bubble
as a single `Liquex.SyntaxError` (or similar) with file/line context.

---

## Filters — crashes on `nil` / non-list inputs

### 6. `(1..3) | map: 'foo'` (unknown property on enumerable) — Low

Raises `FunctionClauseError`. Liquid produces a literal output string:
`"Liquid error: cannot select the property 'foo'"`. The convention of
embedding error messages in output (rather than raising) is widespread in
Liquid.

### 7. Unknown filter — Medium

`{{ 'x' | nope }}` raises `Liquex.Error`. Liquid silently drops the unknown
filter, output is `"x"`.

**Why**: `Render.apply_filter/2` rescues `UndefinedFunctionError`, but the
filter dispatcher uses `String.to_existing_atom/1` which raises `ArgumentError`
for filter names that don't correspond to a known atom — this is rescued
elsewhere as `"Invalid filter <name>"` and re-raised, terminating the render.

**Fix sketch**: When the function lookup fails, push the error onto
`context.errors` and return the input unchanged (Liquid's behavior).

---

## Iteration

### 8. Strings as `for`-loop iterables — Medium

`{% for c in "abc" %}{{ c }}{% endfor %}` raises `Protocol.UndefinedError`.
Liquid yields each character — output `"abc"`.

**Fix sketch**: In `ForTag`, if the collection is a binary, convert via
`String.graphemes/1` before iteration.

### 9. `{% ifchanged %}` not implemented — Low

Crashes parse. Liquid yields the block's content only when the rendered value
differs from the previous iteration; commonly used for grouping output.

### 10. `{% render %}` recursion limit — Low

No `MAX_DEPTH` guard. A self-rendering partial loops forever (or until the
BEAM runs out of stack). Tests at `test/liquex/tag/render_tag_test.exs:166-169`
are pre-existing skipped placeholders for this:

- `recursive render does not produce endless loop`
- `sub contexts count towards the same recursion limit`

**Fix sketch**: Track render depth in `Liquex.Context` (private field), bump
on entry to `RenderTag.render`, raise `Liquex.Error` (or emit Liquid's error
string) when exceeding `100` (Liquid's default).

---

## Output — non-crashing, byte-level differences

### 12. `%Z` zone abbreviation — Low

The host-local `DateTime` we construct in `Filter.build_local_datetime/2` has
`zone_abbr: ""`. `Calendar.strftime(_, "%Z")` therefore prints empty string.
Liquid prints `EST`/`UTC`/etc. via libc.

**Why**: BEAM doesn't expose libc's `tzname` directly. Reading
`/etc/localtime` or shelling to `date +%Z` are the unportable options;
`tzdata` is the portable one but only for IANA-named zones, not the host's
own.

### 13. String `inspect` inside hashes — Low

`Render.inspect_value/1` uses Elixir's `Kernel.inspect/1` for binaries.
Largely matches Ruby's `String#inspect`, but escape sequences for rare
control chars and high-bit bytes may diverge.

---

## Date / timezone

### 15. `'tomorrow'`, `'yesterday'`, relative-date strings — Low

Liquid's `Time.parse` accepts a wide vocabulary of relative date strings via
Ruby's parser. `DateTimeParser` is stricter. Some inputs Liquid silently
accepts return `nil` from Liquex.

### 16. `ENV['TZ']` changes after BEAM boot are ignored — Documented

Erlang caches the timezone at boot via libc. Setting `TZ` mid-process via
`System.put_env/2` is a no-op for `:calendar.local_time/0`. Use
`Liquex.Context.new(.., timezone: "...")` for per-render overrides instead.

---

## Numeric

### 17. Decimal precision at extremes — Low

Liquid uses `Integer` (Bignum) and `BigDecimal`. Liquex uses Elixir's
`Decimal` library. Mostly compatible, but coefficients near `Decimal`'s
precision cap (default 28 digits) may diverge from `BigDecimal`'s arbitrary
precision. Not probed exhaustively.

---

## Likely OK but unverified

These haven't been explicitly probed; flagging in case issues turn up later.

- Whitespace control inside nested `liquid` tags.
- `{% liquid %}` tag with embedded inline (`#`) comments.
- `Liquex.Indifferent.fetch/2` using `String.to_existing_atom/1` —
  potential miss if the atom hasn't been loaded by the time of the lookup
  (struct fields).

---

## Highest-leverage to tackle next

By impact:

1. **#1 + #2 (numeric junk + `{{ 1 == 1 }}` swallow)** — same fix shape
   (lax-Variable junk swallow, plus a numeric-junk fallback in the parser).

Everything else is niche or "no user has reported it yet."

---

## Intentional divergences

These are *known* differences from Ruby Liquid that we will not fix because
the cost outweighs the benefit. Templates that depend on these behaviors
need to be adjusted before porting, not Liquex.

### Multi-key hash ordering

`{{ h }}` for `{"b":2,"a":1}` renders:

- Liquid: `{"b"=>2, "a"=>1}` (Ruby hashes preserve insertion order natively)
- Liquex: `{"a"=>1, "b"=>2}` (Erlang map iteration, key-sorted for ≤32 keys
  and hash-table order beyond)

**Why we won't fix it**: matching Ruby would require routing every map-using
surface — `Indifferent`, `Resolver`, `Render.inspect_value`, every filter
that takes a hash (`map`, `where`, `sort_by`, `size`), `for`-loop iteration,
equality — through a wrapper struct (e.g., `Jason.OrderedObject`) that
preserves insertion order. That wrapper has O(n) lookups versus native
`Map.fetch`'s O(log n), and templates that do `{{ h.key }}` repeatedly eat
that cost on every access. The behavior only affects one rendering case
(`{{ h }}` printing the whole hash inline) which is rare in production
templates — most read fields explicitly or iterate. Liquex is intentionally
faster than Ruby Liquid; this gap is the price.

**Workaround for templates that depend on hash-inspect order**: pre-serialize
the hash to a string before passing it into the context (e.g., via
`Jason.encode!/1` or a custom formatter), or render fields explicitly
instead of relying on the whole-hash dump.
