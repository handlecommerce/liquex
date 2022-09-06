defmodule Liquex.Parser.Object do
  @moduledoc false

  import NimbleParsec

  alias Liquex.Parser.Argument
  alias Liquex.Parser.Field
  alias Liquex.Parser.Literal

  @spec arguments(NimbleParsec.t()) :: NimbleParsec.t()
  defp arguments(combinator \\ empty()) do
    combinator
    |> choice([
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

  @spec keyword_fields(NimbleParsec.t()) :: NimbleParsec.t()
  def keyword_fields(combinator \\ empty()) do
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

  @spec filter(NimbleParsec.t()) :: NimbleParsec.t()
  def filter(combinator \\ empty()) do
    combinator
    |> ignore(Literal.whitespace())
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

  @spec object(NimbleParsec.t()) :: NimbleParsec.t()
  def object(combinator \\ empty()) do
    combinator
    |> ignore(string("{{"))
    |> ignore(optional(string("-")))
    |> ignore(Literal.whitespace())
    |> Argument.argument()
    |> optional(tag(repeat(filter()), :filters))
    |> ignore(Literal.whitespace())
    |> ignore(choice([close_object_remove_whitespace(), string("}}")]))
    |> tag(:object)
  end

  @spec close_object_remove_whitespace(NimbleParsec.t()) :: NimbleParsec.t()
  def close_object_remove_whitespace(combinator \\ empty()) do
    combinator
    |> string("-}}")
    |> Literal.whitespace()
  end
end
