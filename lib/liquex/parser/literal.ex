defmodule Liquex.Parser.Literal do
  @moduledoc false

  import NimbleParsec

  alias Liquex.Parser.Argument

  @spec whitespace(NimbleParsec.t(), non_neg_integer()) :: NimbleParsec.t()
  def whitespace(combinator \\ empty(), min \\ 0) do
    combinator
    |> utf8_string([?\s, ?\n, ?\r, ?\t], min: min)
  end

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

  defp quoted_string do
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
