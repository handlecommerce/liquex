defmodule Liquex.Tag.RenderTag do
  @moduledoc false

  @behaviour Liquex.Tag
  import NimbleParsec

  alias Liquex.Parser.Field
  alias Liquex.Parser.Literal
  alias Liquex.Parser.Object
  alias Liquex.Parser.Tag

  alias Liquex.Context

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

  def render([template: {:literal, template_name}], %Context{file_system: file_system} = context) do
    contents =
      file_system
      |> file_system.__struct__.read_template_file(template_name)
      |> Liquex.parse!()

    Liquex.Render.render(contents, context)
  end
end
