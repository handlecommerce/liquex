defmodule Liquex.Parser.Object do
  @moduledoc """
  Helper methods for parsing object tags and arguments used by objects
  """

  import NimbleParsec

  alias Liquex.Parser.Argument
  alias Liquex.Parser.Field
  alias Liquex.Parser.Literal

  @doc """
  Parse arguments. Arguments are key/value pairs, but a key may have multiple
  values separated by commas.

  ## Examples

      * "img_url: '400x400', crop: 'bottom', filter: 'blur'"
      * "img_size: 800, 600"
  """
  @spec arguments(NimbleParsec.t()) :: NimbleParsec.t()
  def arguments(combinator \\ empty()) do
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

  @doc """
  Parse keyword field

  ## Examples

      * "key: value"
  """
  def keyword_field(combinator) do
    combinator
    |> concat(Field.identifier())
    |> ignore(string(":"))
    |> ignore(Literal.whitespace())
    |> concat(Argument.argument())
    |> tag(:keyword)
  end

  @doc """
  Parses filter that starts with a pipe

  ## Examples

      * "| sort"
      * "| at_most: 5"
  """
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
end
