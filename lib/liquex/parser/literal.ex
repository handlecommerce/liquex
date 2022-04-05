defmodule Liquex.Parser.Literal do
  @moduledoc false

  import NimbleParsec

  alias Liquex.Parser.Argument

  @spec boolean(NimbleParsec.t()) :: NimbleParsec.t()
  defp boolean(combinator \\ empty()) do
    true_value = replace(string("true"), true)
    false_value = replace(string("false"), false)

    choice(combinator, [true_value, false_value])
  end

  @spec nil_value(NimbleParsec.t()) :: NimbleParsec.t()
  defp nil_value(combinator \\ empty()),
    do: combinator |> string("nil") |> replace(nil)

  @spec quoted_string(NimbleParsec.t()) :: NimbleParsec.t()
  defp quoted_string(combinator \\ empty()) do
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

  @spec whitespace(NimbleParsec.t(), non_neg_integer()) :: NimbleParsec.t()
  def whitespace(combinator \\ empty(), min \\ 0) do
    combinator
    |> utf8_string([?\s, ?\n, ?\r, ?\t], min: min)
  end

  @spec ignored_leading_whitespace(NimbleParsec.t()) :: NimbleParsec.t()
  def ignored_leading_whitespace(combinator \\ empty()) do
    combinator
    |> whitespace(1)
    |> lookahead(
      choice([
        string("{%-"),
        string("{{-")
      ])
    )
    |> ignore()
  end

  @spec int(NimbleParsec.t()) :: NimbleParsec.t()
  defp int(combinator \\ empty()) do
    combinator
    |> optional(string("-"))
    |> concat(integer(min: 1))
    |> reduce({Enum, :join, []})
    |> map({String, :to_integer, []})
  end

  @spec float(NimbleParsec.t()) :: NimbleParsec.t()
  defp float(combinator \\ empty()) do
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

  @spec text(NimbleParsec.t()) :: NimbleParsec.t()
  def text(combinator \\ empty()) do
    combinator
    |> lookahead_not(opening_tag())
    |> utf8_char([])
    |> times(min: 1)
    |> reduce({Kernel, :to_string, []})
    |> unwrap_and_tag(:text)
  end

  @spec opening_tag(NimbleParsec.t()) :: NimbleParsec.t()
  def opening_tag(combinator \\ empty()) do
    combinator
    |> choice([
      whitespace(empty(), 1) |> string("{{-"),
      whitespace(empty(), 1) |> string("{%-"),
      string("{{"),
      string("{%")
    ])
  end
end
