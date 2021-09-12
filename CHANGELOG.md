# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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