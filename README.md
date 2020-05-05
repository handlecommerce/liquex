# Liquex

A [Liquid](https://shopify.github.io/liquid/) template parser for Elixir.

A goal for this project is to be 100% compatible with Shopify's Liquid templating engine for ruby.

## Installation

The package is [available in Hex](https://hex.pm/packages/liquex) and can be installed
by adding `liquex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:liquex, "~> 0.3"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/liquex](https://hexdocs.pm/liquex).

## Support

Liquex's goal is 100% byte for byte compatibility with [Liquid](https://shopify.github.com/liquid/). The current
state of the project can be seen here:

**_Supported:_**

- [x] All tags
- [x] All filters
- [x] Objects and variables
- [x] Custom filter
- [x] Custom tags
- [x] Date processing parity with Ruby

**_Not yet implemented_**

- [.] Full whitespace control
- [.] Full test suite using Liquid gem
