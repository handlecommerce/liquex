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

      context = %Liquex.Context{filter_module: CustomFilter},
      {:ok, template_ast} = Liquex.parse("{{'Hello World' | scream}}",

      {result, _} =  Liquex.render(template_ast, context)
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

      defmodule CustomRenderer do
        def render({:custom_tag, contents}, context) do
          {result, context} = Liquex.render(contents, context)

          {["Custom Tag: ", result], context}
        end
      end

      context = %Liquex.Context{render_module: CustomRenderer}

      {:ok, document} = Liquex.parse("<<Hello World!>>", CustomParser)
      {result, _} = Liquex.render(document, context)

      result |> to_string()
      iex> "Custom Tag: Hello World!"


  ## Installation

  Add the package to your `mix.exs` file.

      def deps do
        [{:liquex, "~> 0.2.1"}]
      end

  """

  alias Liquex.Context

  alias Liquex.Render.{
    ControlFlow,
    Iteration,
    Object,
    Variable
  }

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

  @spec render(document_t(), Context.t()) :: {iolist(), Context.t()}
  @doc """
  Renders a Liquid AST `document` into an `iolist`

  A `context` is given to handle temporary contextual information for
  this render.
  """
  def render(document, context \\ %Context{}),
    do: do_render_custom([], document, context)

  @spec do_render(iolist(), document_t(), Context.t()) :: {iolist(), Context.t()}
  defp do_render_custom(content, [tag | tail], %{render_module: mod} = context)
       when not is_nil(mod) do
    case mod.render(tag, context) do
      {:ok, result, context} ->
        [result | content]
        |> do_render(tail, context)

      _ ->
        do_render(content, [tag | tail], context)
    end
  end

  defp do_render_custom(content, list, context), do: do_render(content, list, context)

  defp do_render(content, [], context),
    do: {content |> Enum.reverse(), context}

  defp do_render(content, [{:text, text} | tail], context) do
    [text | content]
    |> do_render(tail, context)
  end

  defp do_render(content, [{:object, object} | tail], context) do
    result = Object.render(object, context)

    [result | content]
    |> do_render(tail, context)
  end

  defp do_render(content, [{:control_flow, tag} | tail], context) do
    {result, context} = ControlFlow.render(tag, context)

    [result | content]
    |> do_render(tail, context)
  end

  defp do_render(content, [{:variable, tag} | tail], context) do
    {result, context} = Variable.render(tag, context)

    [result | content]
    |> do_render(tail, context)
  end

  defp do_render(content, [{:iteration, tag} | tail], context) do
    {result, context} = Iteration.render(tag, context)

    [result | content]
    |> do_render(tail, context)
  end
end
