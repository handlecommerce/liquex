defmodule Liquex do
  @moduledoc """
  Liquid template renderer for Elixir with a goal of 100% compatibility with the
  [Liquid](https://shopify.github.io/liquid/) gem by [Shopify](https://www.shopify.com/).

  ## Basic Usage

      iex> {:ok, template_ast} = Liquex.parse("Hello {{ name }}!")
      iex> context = Liquex.Context.new(%{"name" => "World"})
      iex> {content, _context} = Liquex.render(template_ast, context)
      iex> content |> to_string()
      "Hello World!"

  ## Supported features

  Currently, all standard Liquid tags, filters, and types are fully supported.  Liquex can
  be considered a drop in replacement of the Liquid gem, but in Elixir.

  There is a caveat that must be noted:

  ***Whitespace control is partially supported.***

  [Whitespace control](https://shopify.github.io/liquid/basics/whitespace/) is only partially
  supported.  Whitespace is successfully removed after `-%}` and `-}}` tags.  However, whitespace
  isn't removed from the left side yet, before `{%-` and `{{-`.  This is because we're using
  [NimbleParsec](https://github.com/dashbitco/nimble_parsec) which does not support greedy matches.
  Instead, we will need to do post processing to properly remove spaces.  As whitespace control is
  deemed of low importance for most applications, this has not been prioritized.


  ## Lazy variables

  Liquex allows resolver functions for variables that may require some extra
  work to generate. For example, Shopify has variables for things like
  available products. Pulling all products every time would be too expensive
  to do on every render. Instead, it would be better to lazily pull that
  information as needed.

  Instead of adding the product list to the context variable map, you can add
  a function to the variable map. If a function is accessed in the variable
  map, it is executed.

      products_resolver = fn _parent -> Product.all() end

      with context <- Liquex.Context.new(%{products: products_resolver}),
          {:ok, document} <- Liquex.parse("There are {{ products.size }} products"),
          {result, _} <- Liquex.render(document, context) do
        result
      end

      iex> "There are 5 products"

  ## Indifferent access

  By default, Liquex accesses your maps and structs that may have atom or
  string (or other type) keys. Liquex will try a string key first. If that
  fails, it will fall back to using an atom keys.  This is similar to how
  Ruby on Rails handles many of its hashes.

  This allows you to pass in your structs without having to replace all your
  keys with string keys.

      iex> {:ok, template_ast} = Liquex.parse("Hello {{ name }}!")
      iex> context = Liquex.Context.new(%{name: "World"})
      iex> {content, _context} = Liquex.render(template_ast, context)
      iex> content |> to_string()
      "Hello World!"

  ## Custom filters

  Liquex contains the full suite of standard Liquid filters, but you may find that there are still
  filters that you may want to add.

  Liquex supports adding your own custom filters to the render pipeline.  When creating the context
  for the renderer, set the filter module to your own module.

      defmodule CustomFilter do
        # Import all the standard liquid filters
        use Liquex.Filter

        def scream(value, _), do: String.upcase(value) <> "!"
      end

      context = Liquex.Context.new(%{}, filter_module: CustomFilter)
      {:ok, template_ast} = Liquex.parse("{{'Hello World' | scream}}"

      {result, _} = Liquex.render(template_ast, context)
      result |> to_string()

      iex> "HELLO WORLD!"

  ## Custom tags

  One of the strong points for Liquex is that the tag parser can be extended to support non-standard
  tags.  For example, Liquid used internally for the Shopify site includes a large range of tags that
  are not supported by the base Ruby gem.  These tags could also be added to Liquex by extending the
  liquid parser.


      defmodule CustomTag do
        import NimbleParsec
        alias Liquex.Parser.Base

        # Parse <<Custom Tag>>
        def custom_tag(combinator \\\\ empty()) do
          text =
            lookahead_not(string(">>"))
            |> utf8_char([])
            |> times(min: 1)
            |> reduce({Kernel, :to_string, []})
            |> tag(:text)

          combinator
          |> ignore(string("<<"))
          |> optional(text)
          |> ignore(string(">>"))
          |> tag(:custom_tag)
        end

        def element(combinator \\\\ empty()) do
          # Add the `custom_tag/1` parsing function to the supported element tag list
          combinator
          |> choice([custom_tag(), Base.base_element()])
        end
      end

      defmodule CustomParser do
        @moduledoc false
        import NimbleParsec

        defcombinatorp(:document, repeat(CustomTag.element()))
        defparsec(:parse, parsec(:document) |> eos())
      end

      iex> Liquex.parse("<<Hello World!>>", CustomParser)
      iex> {:ok, [custom_tag: [text: ["Hello World!"]]]}

  ## Custom renderer

  In many cases, if you are building custom tags for your Liquid documents, you probably want to
  use a custom renderer.  Just like the custom filters, you add your module to the context object.

      defmodule CustomTagRender do
        def render({:custom_tag, contents}, context) do
          {result, context} = Liquex.render(contents, context)

          {["Custom Tag: ", result], context}
        end

        # Ignore this tag if we don't match
        def render(_, _), do: false
      end

      context = %Liquex.Context.new(%{}, render_module: CustomTagRender)

      {:ok, document} = Liquex.parse("<<Hello World!>>", CustomParser)
      {result, _} = Liquex.render(document, context)

      result |> to_string()
      iex> "Custom Tag: Hello World!"


  ## Installation

  Add the package to your `mix.exs` file.

      def deps do
        [{:liquex, "~> 0.4"}]
      end

  """

  alias Liquex.Context

  @type document_t :: [
          {:control_flow, nonempty_maybe_improper_list}
          | {:iteration, [...]}
          | {:object, [...]}
          | {:text, any}
          | {:variable, [...]}
        ]

  @spec parse(String.t(), module) :: {:ok, document_t} | {:error, String.t(), pos_integer()}
  @doc """
  Parses a liquid `template` string using the given `parser`.

  Returns a liquid AST document or the parser error
  """
  def parse(template, parser \\ Liquex.Parser) do
    case parser.parse(template) do
      {:ok, content, _, _, _, _} -> {:ok, content}
      {:error, reason, _, _, {line, _}, _} -> {:error, reason, line}
    end
  end

  @spec render(document_t, Context.t()) :: {iolist, Context.t()}
  @doc """
  Render a Liquex AST `document` with the given `context`
  """
  def render(document, context \\ %Context{}),
    do: Liquex.Render.render([], document, context)
end
