defmodule Liquex.Parsers.Literals do
  import NimbleParsec

  def boolean(combinator \\ empty()) do
    true_value = string("true") |> replace(true)
    false_value = string("false") |> replace(false)

    combinator
    |> choice([true_value, false_value])
  end

  def nil_value(combinator \\ empty()),
    do: combinator |> string("nil") |> replace(nil)

  @spec quoted_string(NimbleParsec.t()) :: NimbleParsec.t()
  def quoted_string(combinator \\ empty()) do
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

    combinator
    |> choice([single_quote_string, double_quote_string])
  end

  def whitespace(combinator \\ empty()) do
    combinator
    |> ascii_char([?\s, ?\n, ?\r])
    |> times(min: 0)
  end

  def int(combinator \\ empty()) do
    combinator
    |> optional(string("-"))
    |> concat(integer(min: 1))
    |> reduce({Enum, :join, []})
    |> map({String, :to_integer, []})
  end

  def float(combinator \\ empty()) do
    combinator
    |> int()
    |> string(".")
    |> concat(integer(min: 1))
    |> optional(
      utf8_string([?e, ?E], 1)
      |> optional(utf8_string([?+, ?-], 1))
      |> integer(min: 1)
    )
    |> reduce({Enum, :join, []})
    |> map({String, :to_float, []})
  end

  def literal(combinator \\ empty()) do
    combinator
    |> choice([
      boolean(),
      nil_value(),
      float(),
      int(),
      quoted_string()
    ])
    |> unwrap_and_tag(:literal)
  end
end
