# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `Liquex.Drop` behaviour for context-aware indifferent-access "drops".
  Modules implementing `fetch/3` are dispatched directly from `.` traversal
  in templates, with results memoized for the duration of a single render.
  Repeat references to `{{ products.first.category.name }}` within one
  render only invoke the underlying drop fetches once. Stateful drops can
  opt out per-module with `def cacheable?(_), do: false`.
- `use Liquex.Drop` + `defliquid name(drop, ctx), do: …` macro provides a
  whitelist-checked, method-style way to declare drop attributes. Compiles
  to direct `case`-dispatched `fetch/3` clauses (no runtime `apply`
  overhead). Pass `cacheable: false` to skip per-render memoization for
  drops whose attributes are cheap pure computations.
- `Liquex.Drop.Forloop` and `Liquex.Drop.TablerowLoop` back the `forloop`
  and `tablerowloop` template variables. Previously these were precomputed
  maps; now they are tiny immutable structs whose attributes derive on
  demand. Closes a small parity gap: `tablerowloop.col0`, `index0`,
  `length`, `rindex`, and `rindex0` now have explicit test coverage.
- `Liquex.Cache.memoize/3` — ergonomic helper over the existing
  `Liquex.Cache` behaviour for custom filter authors who want per-render
  memoization of expensive operations.

### Fixed

- `'2024-01-02 12:00:00' | date: '%z'` previously rendered an empty
  offset because string parses produced `NaiveDateTime` with no zone
  attached. Now mirrors Liquid's `Time.parse` behavior: unzoned string
  inputs are interpreted in the host-local zone (or the `:timezone`
  context override). Strings with explicit offsets continue to be used
  as-is. Closes the date-filter parity story.
- `nil | join`, `nil | sort`, `nil | sort_natural`, `nil | uniq`,
  `nil | compact`, `nil | map`, `nil | reject`, `nil | where`, and
  `nil | reverse` now return Liquid's expected empty value (`""` for
  `join`, `[]` for the rest) instead of raising on the missing
  Enumerable impl.

### Changed (breaking)

- **Drops are the only way for user-defined structs to participate in
  template traversal beyond direct field access.** `@behaviour Access`
  on a user struct is no longer dispatched by Liquex's resolver. If you
  had a struct with `@behaviour Access` and a custom `fetch/2` to drive
  template lookups, port it to `@behaviour Liquex.Drop` (or
  `use Liquex.Drop` with `defliquid` declarations) and rename `fetch/2`
  to `fetch/3` — the third argument is the render context, which you can
  ignore (`_context`). Plain structs without a behaviour still resolve
  field access by atom or string key.
- `Liquex.Argument.eval/2` and `Liquex.Expression.eval/2` now return
  `{value, context}` tuples (previously just `value`). All in-tree tag
  callers updated. Custom tags that call these directly will need to
  destructure the return value.
- `Liquex.Filter.apply/4` now returns `{value, context}` so cache writes
  triggered by filter argument evaluation propagate. Custom filter modules
  that override `apply/3` to return just a value continue to work — the
  render pipeline accepts both shapes.
- `Liquex.Representable.is_lazy/1` callback renamed to `lazy?/1` per
  Elixir naming convention. Implementors must rename their function.
- `Liquex.Tag.RenderTag` partial-template parse cache now uses
  `Liquex.Cache.memoize/3` internally. Cache key format changed from a
  string (`"prefix:Liquex.Tag.RenderTag:partial.NAME"`) to a tuple
  (`{prefix, {Liquex.Tag.RenderTag, :partial, "NAME"}}`). Only relevant if
  you have a custom `Liquex.Cache` implementation that introspects keys.

## [0.14.0] - 2026-05-02

A round of byte-for-byte parity work against the Liquid gem. Most changes are
bug fixes that bring output closer to Ruby Liquid; a handful alter output for
templates that already worked, called out under "Behavior changes" below.

### Added

- `empty`, `blank`, and `null` are now reserved literal keywords, parsed
  via a `Liquex.Special` sentinel. `'' == empty`, `[] == empty`, and
  `{} == empty` evaluate to true; `nil == empty` and `nil == blank`
  evaluate to false, matching Liquid's `MethodLiteral` semantics.
- Maps render in Ruby's hash-inspect form (`{"a"=>1}`, with nested arrays
  as `[1, 2]`), and ranges render as `1..3`. Both previously crashed.
- Ranges work as filter inputs (`{{ (1..3) | join: "," }}`,
  `{{ (1..3) | size }}`, etc.) by being normalized to a list when entering
  the filter pipeline.
- `Liquex.Context.new/2` accepts a `:timezone` option (e.g.
  `"America/New_York"`). When set, the `date` filter renders `'now'`,
  `'today'`, and integer Unix timestamps in that zone. See "Timezone
  notes" below for the tzdata requirement.
- `{% assign x = ... %}` accepts comparison and boolean operators between
  the value and the filter chain, matching Liquid's lax `Variable` parser
  (`{% assign x = 1 == 1 | append: '!' %}` -> `1!`). Previously crashed.

### Behavior changes

- The `date` filter for `'now'`, `'today'`, and integer Unix timestamps
  now defaults to the **host's local timezone** (read from `ENV['TZ']`
  via libc), matching Ruby's `Time.now`/`Time.at`. It previously rendered
  in UTC. Set `TZ=UTC` on the host or pass `timezone: "Etc/UTC"` to
  `Liquex.Context.new/2` to restore the old behavior.
- Ranges are forward-only: `(5..1)` iterates as empty (matching Liquid),
  not `[5, 4, 3, 2, 1]`. The range still prints as `"5..1"`.
- Float output matches Ruby's `Float#to_s`: decimal notation in
  `[1e-4, 1e15)`, scientific elsewhere with a sign-prefixed two-digit
  exponent (`1.0e-05`, `1.0e+15`). Previously used Elixir's
  `Float.to_string/1` thresholds and exponent format.
- Numeric coercion of strings with trailing junk follows Ruby's `to_i`.
  `'4.6abc' | ceil` is now `4` (was `0`); `'4abc' | plus: 0` is `4`.
- Maps render via the inspect form rather than crashing. Map iteration
  order is whatever Erlang's map ordering produces -- usually
  alphabetical by key for small maps, which differs from Ruby's
  insertion order. Single-key hashes always match byte-for-byte; tests
  asserting multi-key hash output should use single-key fixtures or
  alphabetically-ordered keys.

### Fixed

- `'hello' | truncate: 0` and other non-positive lengths return the
  ellipsis instead of crashing.
- `s.first`, `s.last`, and other unknown property access on strings
  return `nil` instead of raising `FunctionClauseError`. `s.size` still
  works.
- Datetime strings with timezone components no longer crash format
  directives like `%H`/`%M`/`%S` (the parsed datetime is no longer
  degraded to a `Date`).
- With a tzdata-backed `Calendar.TimeZoneDatabase` configured,
  `'2024-01-02 12:34:56 +0500' | date: '%z'` correctly preserves the
  parsed offset.

### Timezone notes

- The `date` filter and the new `:timezone` context option lean on
  Elixir's `Calendar.TimeZoneDatabase`. Stock Elixir ships
  `Calendar.UTCOnlyTimeZoneDatabase`, which only supports UTC. To use
  named zones (`"America/New_York"`, etc.) or to preserve offsets parsed
  from string inputs, add `{:tzdata, "~> 1.1"}` to your deps and call
  `Calendar.put_time_zone_database(Tzdata.TimeZoneDatabase)` once at
  boot. Without it, `:timezone` accepts only `"Etc/UTC"` and string
  inputs with offsets degrade to offset-less `NaiveDateTime` (the same
  silent fallback Liquex had before).
- The integration suite forwards `ENV['TZ']` to the Ruby subprocess so
  Liquid and Liquex stay in sync regardless of the developer's machine.
  CI should pin `TZ` (e.g. `TZ=UTC mix test`) for reproducibility.

## [0.13.1] - 2024-07-19

- Fix warning in Elixir 1.17 [#47](https://github.com/handlecommerce/liquex/pull/47)
  - Thank you [tmjoen](https://github.com/tmjoen)

## [0.13.0] - 2024-04-26

- Add support for recursive liquid tags [#1731](https://github.com/Shopify/liquid/pull/1731)
- Match rounding precision to ruby gem when using the `round` filter with invalid precision.

## [0.12.0] - 2024-01-24

- Add support for inline comments

## [0.11.0] - 2023-12-20

- Remove dependency on Timex.
- Update other dependencies.

## [0.10.2] - 2023-09-19

- Add cache prefix for multitenancy [#44](https://github.com/handlecommerce/liquex/pull/44)
  - Thank you [dkulchenko](https://github.com/dkulchenko)
    Allow the cache to have a prefix to support multiple caches in case Liquex
    is used in a multitenant environment

## [0.10.1] - 2023-03-10

- Deprecated Liquex.render/2 for Liquex.render!/2
    Liquex.render/2 will be replaced with a function that returns an error tuple
    instead of raising an error in 0.11
- Add devcontainer
- Fix regression on round filter with invalid inputs

## [0.10.0] - 2022-12-19

- Add {% liquid %} tag to follow Liquid 5.0.0.

## [0.9.0] - 2022-09-14

- Add {% render %} tag to follow Liquid 5.0.0.
- Add caching behaviour for use in {% render %} tag.

## [0.8.0] - 2022-09-04

- Migrate all tags into using the new tag system originally defined by custom tag handler
- Add .last handler
- Fix issue where `break` and `continue` would throw away prior content in same scope
- Allow date filter to handle nil values [#34](https://github.com/markglenn/liquex/issues/34)
  - Thank you [stevencorona](https://github.com/stevencorona)
- Removed deprecated custom renderer code.

## [0.7.2] - 2022-04-19

- Fix struct access in liquid template regression [#31](https://github.com/markglenn/liquex/issues/31)

## [0.7.1] - 2022-03-31

- Allow accessing variables that implement the Access behaviour [#26](https://github.com/markglenn/liquex/pull/26)
- Allow types supporting String.Chars protocol to be used in string operations [#23](https://github.com/markglenn/liquex/pull/23)
  - Thank you [cipater](https://github.com/cipater)
- Allow multiple values in case statements [#29](https://github.com/markglenn/liquex/pull/29)
  - Thank you [ouven](https://github.com/ouven)

## [0.7.0] - 2021-09-17

- Refactored custom tags for better developer experience [#20](https://github.com/markglenn/liquex/issues/20)
  - Deprecated old custom tags format
- Added `Liquex.parse!/2` that raises an exception instead of returning an error tuple

## [0.6.3] - 2021-09-14

- Capture variables as strings instead of an iodata [#17](https://github.com/markglenn/liquex/pull/17)
  - Thank you [resterle](https://github.com/resterle)
- Optimize compilation speed [#19](https://github.com/markglenn/liquex/pull/19) [#18](https://github.com/markglenn/liquex/issues/18)
  - Thank you [tmjoen](https://github.com/tmjoen)

## [0.6.2] - 2021-09-12

- Fix object access using evaluated and literal args. [#15](https://github.com/markglenn/liquex/pull/15)
  - Thank you [ouven](https://github.com/ouven)

## [0.6.1] - 2021-06-30

- Fix `contains` to_existing_atom call. [#12](https://github.com/markglenn/liquex/issues/12)

## [0.6.0] - 2021-04-11

This release is now 100% compatible with the
[Liquid](https://github.com/Shopify/liquid) gem for ruby.

### Added

- Whitespace control using `{%-` and `{{-`

## [0.5.0] - 2020-10-22

### Added

- Indifferent access in structs/maps using string or atom keys

## [0.4.2] - 2020-09-26

### Added

- Sort and where clauses to Liquex.Collection

### Fixed

- Fixed issue where identifiers could not end in question marks

## [0.4.1] - 2020-09-05

### Added

- `{% assign %}` now allows the use of filters

## [0.4.0] - 2020-08-16

### Added

- `Liquex.Collection` added for for custom iterators
- `Liquex.Represent` added for lazy object rendering
