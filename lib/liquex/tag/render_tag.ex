defmodule Liquex.Tag.RenderTag do
  @moduledoc false

  @behaviour Liquex.Tag
  import NimbleParsec

  alias Liquex.Argument
  alias Liquex.FileSystem

  alias Liquex.Parser.Field
  alias Liquex.Parser.Literal
  alias Liquex.Parser.Object
  alias Liquex.Parser.Tag

  alias Liquex.Tag.ForTag

  alias Liquex.Context

  @spec parse :: NimbleParsec.t()
  def parse do
    ignore(
      Tag.open_tag()
      |> string("render")
      |> Literal.whitespace()
    )
    |> Literal.literal()
    |> unwrap_and_tag(:template)
    |> optional(choice([keyword_list(), with_clause(), for_loop()]))
    |> ignore(Tag.close_tag())
  end

  defp keyword_list do
    string(",")
    |> Literal.whitespace()
    |> ignore()
    |> Object.keyword_fields()
    |> tag(:keywords)
  end

  defp with_clause do
    Literal.whitespace(empty(), 1)
    |> string("with")
    |> Literal.whitespace(1)
    |> ignore()
    |> Field.field()
    |> optional(alias())
    |> tag(:with)
  end

  defp for_loop do
    Literal.whitespace(empty(), 1)
    |> string("for")
    |> Literal.whitespace(1)
    |> ignore()
    |> unwrap_and_tag(Field.field(), :collection)
    |> optional(alias())
    |> tag(:for)
  end

  defp alias do
    empty()
    |> Literal.whitespace(1)
    |> string("as")
    |> Literal.whitespace(1)
    |> ignore()
    |> Field.identifier()
    |> unwrap_and_tag(:as)
  end

  def render(
        [template: template],
        %Context{} = context
      ) do
    render([template: template, keywords: []], context)
  end

  def render(
        [template: template, keywords: keywords],
        %Context{} = context
      ) do
    new_context = apply_keywords_to_context(context, keywords)

    template
    |> load_contents(context)
    |> Liquex.Render.render(new_context)
    |> case do
      {content, _new_context} -> {content, context}
      # break/continue do not get propagated to parent context
      {_operation, content, _new_context} -> {content, context}
    end
  end

  # Handle with field as alias
  #
  # {% render "template_name" with field as identifier %}
  def render([template: template, with: [field: field, as: identifier]], context) do
    keywords = [keyword: [identifier, [field: field]]]
    render([template: template, keywords: keywords], context)
  end

  # Handle with field without alias
  #
  # {% render "template_name" with field %}
  def render([template: {:literal, template_name}, with: field], context) do
    keywords = [keyword: [template_name, field]]
    render([template: {:literal, template_name}, keywords: keywords], context)
  end

  # Handle for loop without identifier alias
  #
  # {% render "template_name" for collection %}
  def render(
        [template: {:literal, template}, for: [collection: collection]],
        %Context{} = context
      ) do
    # Define the identifier as the template name
    render(
      [
        template: {:literal, template},
        for: [collection: collection, as: template]
      ],
      context
    )
  end

  # Handle for loop with identifier alias
  #
  # {% render "template_name" for collection as identifier %}
  def render(
        [template: template, for: [collection: collection, as: identifier]],
        %Context{} = context
      ) do
    contents = load_contents(template, context)

    new_context = apply_keywords_to_context(context, [])

    # Piggy back off `Liquex.Tag.ForTag` to fully support forloop variable
    {result, _context} =
      collection
      |> Liquex.Argument.eval(context)
      |> Liquex.Expression.eval_collection()
      |> Liquex.Collection.to_enumerable()
      |> ForTag.render_collection(identifier, contents, nil, new_context)

    {result, context}
  end

  @spec apply_keywords_to_context(Context.t(), Keyword.t()) :: Context.t()
  defp apply_keywords_to_context(%Context{} = context, keywords) do
    scope = Map.new(keywords, fn {:keyword, [k, v]} -> {k, Argument.eval(v, context)} end)

    Context.new_isolated_subscope(context, scope)
  end

  @spec load_contents({:literal, String.t()}, Context.t()) :: Liquex.document_t() | no_return()
  defp load_contents({:literal, template_name}, %Context{file_system: file_system, cache: cache}) do
    cache.fetch("template." <> template_name, fn ->
      file_system
      |> FileSystem.read_template_file(template_name)
      |> Liquex.parse!()
    end)
  end
end
