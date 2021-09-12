defmodule Liquex.Parser.Literal do
  @moduledoc false

  import NimbleParsec

  alias Liquex.Parser.Field

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

  def whitespace(combinator \\ empty(), min \\ 0) do
    combinator
    |> utf8_string([?\s, ?\n, ?\r, ?\t], min: min)
  end

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

  @spec argument(NimbleParsec.t()) :: NimbleParsec.t()
  def argument(combinator \\ empty()) do
    combinator
    |> choice([literal(), Field.field()])
  end

  @spec range(NimbleParsec.t()) :: NimbleParsec.t()
  def range(combinator \\ empty()) do
    combinator
    |> ignore(string("("))
    |> ignore(whitespace())
    |> tag(argument(), :begin)
    |> ignore(string(".."))
    |> tag(argument(), :end)
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
defmodule Liquex.Parser.LiteralHelper do
  import NimbleParsec
  import Liquex.Parser.Literal

  defcombinator(:argument, argument())
end
