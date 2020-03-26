# Liquex

A [Liquid](https://shopify.github.io/liquid/) template parser for Elixir.

A goal for this project is to be 100% compatible with Shopify's Liquid templating engine for ruby.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `liquex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:liquex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/liquex](https://hexdocs.pm/liquex).

## Support

- [x] All tags
- [x] All filters
- [x] Objects and variables
- [x] Custom filter
- [x] Custom tags

## TODO

- [ ] Whitespace control
- [ ] Full test suite using Liquid gem
- [ ] Date processing parity with Ruby
