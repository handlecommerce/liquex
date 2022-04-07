defmodule Liquex.Tag.ObjectTag do
  @behaviour Liquex.Tag
  import NimbleParsec

  alias Liquex.Context

  alias Liquex.Parser.Argument
  alias Liquex.Parser.Field
  alias Liquex.Parser.Literal

  alias Liquex.Render

  def parse do
    ignore(string("{{"))
    |> ignore(optional(string("-")))
    |> ignore(Literal.whitespace())
    |> Argument.argument()
    |> optional(tag(repeat(filter()), :filters))
    |> ignore(Literal.whitespace())
    |> ignore(choice([close_object_remove_whitespace(), string("}}")]))
  end

  defp arguments do
    choice([
      Argument.argument()
      |> lookahead_not(string(":"))
      |> repeat(
        ignore(Literal.whitespace())
        |> ignore(string(","))
        |> ignore(Literal.whitespace())
        |> concat(Argument.argument())
        |> lookahead_not(string(":"))
      )
      |> optional(
        ignore(Literal.whitespace())
        |> ignore(string(","))
        |> ignore(Literal.whitespace())
        |> keyword_fields()
      ),
      keyword_fields()
    ])
  end

  defp keyword_fields(combinator \\ empty()) do
    combinator
    |> keyword_field()
    |> repeat(
      ignore(Literal.whitespace())
      |> ignore(string(","))
      |> ignore(Literal.whitespace())
      |> keyword_field()
    )
  end

  defp keyword_field(combinator) do
    combinator
    |> concat(Field.identifier())
    |> ignore(string(":"))
    |> ignore(Literal.whitespace())
    |> concat(Argument.argument())
    |> tag(:keyword)
  end

  def filter do
    ignore(Literal.whitespace())
    |> ignore(utf8_char([?|]))
    |> ignore(Literal.whitespace())
    |> concat(Field.identifier())
    |> tag(
      optional(
        ignore(string(":"))
        |> ignore(Literal.whitespace())
        |> concat(arguments())
      ),
      :arguments
    )
    |> tag(:filter)
  end

  def close_object_remove_whitespace do
    string("-}}")
    |> Literal.whitespace()
  end

  def render([argument, filters: filters], %Context{} = context) do
    {result, context} =
      argument
      |> List.wrap()
      |> Liquex.Argument.eval(context)
      |> Render.apply_filters(filters, context)

    {to_string(result), context}
  end
end
