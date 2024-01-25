defmodule Liquex.Parser.Literal do
  @moduledoc """
  Helper parsers for parsing literal values in Liquid
  """

  import NimbleParsec

  alias Liquex.Parser.Argument

  @doc """
  Parses white space, given a minimum.

  ## Examples

      * "  "
      * "\r\n\t"
      * "# comment"
  """
  @spec whitespace(NimbleParsec.t(), non_neg_integer()) :: NimbleParsec.t()
  def whitespace(combinator \\ empty(), min \\ 0) do
    combinator
    |> utf8_string([?\s, ?\n, ?\r, ?\t], min: min)
  end

  @doc """
  Parses not line breaking white space, given a minimum.

  ## Examples

      * "  "
      * "\t"
  """
  @spec non_breaking_whitespace(NimbleParsec.t(), non_neg_integer()) :: NimbleParsec.t()
  def non_breaking_whitespace(combinator \\ empty(), min \\ 0) do
    combinator
    |> utf8_string([?\s, ?\t], min: min)
  end

  @doc """
  Parses a range

  ## Examples

      * "(1..5)"
      * "(1..num)"
  """
  @spec range(NimbleParsec.t()) :: NimbleParsec.t()
  def range(combinator \\ empty()) do
    combinator
    |> ignore(string("("))
    |> ignore(whitespace())
    |> tag(Argument.argument(), :begin)
    |> ignore(string(".."))
    |> tag(Argument.argument(), :end)
    |> ignore(whitespace())
    |> ignore(string(")"))
    |> tag(:inclusive_range)
  end

  @doc """
  Parses a literal

  ## Examples

      * "true"
      * "false"
      * "nil"
      * "3.14"
      * "3"
      * "'Hello World!'"
      * "\"Hello World!\""
  """
  @spec literal(NimbleParsec.t()) :: NimbleParsec.t()
  def literal(combinator \\ empty()) do
    true_value = replace(string("true"), true)
    false_value = replace(string("false"), false)

    nil_value = replace(string("nil"), nil)

    combinator
    |> choice([
      true_value,
      false_value,
      nil_value,
      float(),
      int(),
      quoted_string()
    ])
    |> unwrap_and_tag(:literal)
  end

  @doc """
  Parses everything outside of the Liquid tags. We call this text but it's any
  unstructed data not specifically parsed by Liquex.
  """
  @spec text(NimbleParsec.t()) :: NimbleParsec.t()
  def text(combinator \\ empty()) do
    opening_tag =
      choice([
        whitespace(empty(), 1) |> string("{{-"),
        whitespace(empty(), 1) |> string("{%-"),
        string("{{"),
        string("{%")
      ])

    combinator
    |> lookahead_not(opening_tag)
    |> utf8_char([])
    |> times(min: 1)
    |> reduce({Kernel, :to_string, []})
    |> unwrap_and_tag(:text)
  end

  @doc """
  Parses a single or double quoted string.

  Strings may have escaped quotes within them.

  ## Examples

  Examples here include the quotes as given, as opposed to other examples.

      * "Hello World"
      * 'Hello World'
      * "Hello \"World\""
      * 'Hello "World"'
      * 'Hello \'World\''
  """
  def quoted_string do
    single_quote_string =
      ignore(utf8_char([?']))
      |> repeat(
        lookahead_not(ascii_char([?']))
        |> choice([string(~s{\'}), utf8_char([])])
      )
      |> ignore(utf8_char([?']))
      |> reduce({List, :to_string, []})

    double_quote_string =
      ignore(utf8_char([?"]))
      |> repeat(
        lookahead_not(ascii_char([?"]))
        |> choice([string(~s{\"}), utf8_char([])])
      )
      |> ignore(utf8_char([?"]))
      |> reduce({List, :to_string, []})

    choice([single_quote_string, double_quote_string])
  end

  defp int do
    optional(string("-"))
    |> concat(integer(min: 1))
    |> reduce({Enum, :join, []})
    |> map({String, :to_integer, []})
  end

  defp float do
    exponent =
      utf8_string([?e, ?E], 1)
      |> optional(utf8_string([?+, ?-], 1))
      |> integer(min: 1)

    optional(string("-"))
    |> concat(integer(min: 1))
    |> string(".")
    |> concat(integer(min: 1))
    |> optional(exponent)
    |> reduce({Enum, :join, []})
    |> map({String, :to_float, []})
  end
end
