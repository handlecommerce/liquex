defmodule Liquex.Tag.CaptureTag do
  @moduledoc false

  @behaviour Liquex.Tag

  alias Liquex.Context
  alias Liquex.Parser.Field
  alias Liquex.Parser.Literal
  alias Liquex.Parser.Tag

  import NimbleParsec

  def parse do
    ignore(Tag.open_tag())
    |> ignore(string("capture"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> unwrap_and_tag(Field.identifier(), :identifier)
    |> ignore(Tag.close_tag())
    |> tag(parsec(:document), :contents)
    |> ignore(Tag.tag_directive("endcapture"))
  end

  def render([identifier: identifier, contents: contents], %Context{} = context) do
    {rendered_contents, context} = Liquex.render(contents, context)
    {[], Context.assign(context, identifier, to_string(rendered_contents))}
  end
end
