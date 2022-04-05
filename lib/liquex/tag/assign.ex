defmodule Liquex.Tag.Assign do
  @behaviour Liquex.Tag

  alias Liquex.Context
  alias Liquex.Parser.Tag
  alias Liquex.Parser.Argument
  alias Liquex.Parser.Object
  alias Liquex.Parser.Literal
  alias Liquex.Parser.Field

  alias Liquex.Render.Filter

  import NimbleParsec

  def parse do
    literal_and_filters =
      Argument.argument()
      |> optional(tag(repeat(Object.filter()), :filters))

    ignore(Tag.open_tag())
    |> ignore(string("assign"))
    |> ignore(Literal.whitespace())
    |> unwrap_and_tag(Field.identifier(), :left)
    |> ignore(Literal.whitespace())
    |> ignore(string("="))
    |> ignore(Literal.whitespace())
    |> tag(literal_and_filters, :right)
    |> ignore(Tag.close_tag())
  end

  def render([left: left, right: [right, filters: filters]], %Context{} = context)
      when is_binary(left) do
    {right, context} =
      right
      |> Liquex.Argument.eval(context)
      |> Filter.apply_filters(filters, context)

    context = Context.assign(context, left, right)

    {[], context}
  end
end
