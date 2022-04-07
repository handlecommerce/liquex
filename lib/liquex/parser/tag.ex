defmodule Liquex.Parser.Tag do
  @moduledoc false

  import NimbleParsec

  alias Liquex.Parser.Argument
  alias Liquex.Parser.Literal

  @spec open_tag(NimbleParsec.t()) :: NimbleParsec.t()
  def open_tag(combinator \\ empty()) do
    combinator
    |> string("{%")
    |> optional(string("-"))
    |> Literal.whitespace()
  end

  @spec close_tag(NimbleParsec.t()) :: NimbleParsec.t()
  def close_tag(combinator \\ empty()) do
    combinator
    |> Literal.whitespace()
    |> choice([close_tag_remove_whitespace(), string("%}")])
  end

  @spec tag_directive(NimbleParsec.t(), String.t()) :: NimbleParsec.t()
  def tag_directive(combinator \\ empty(), name) do
    combinator
    |> open_tag()
    |> string(name)
    |> close_tag()
  end

  @spec expression_tag(NimbleParsec.t(), String.t()) :: NimbleParsec.t()
  def expression_tag(combinator \\ empty(), tag_name) do
    combinator
    |> ignore(open_tag())
    |> ignore(string(tag_name))
    |> ignore(Literal.whitespace())
    |> tag(boolean_expression(), :expression)
    |> ignore(close_tag())
  end

  # Close tag that also removes the whitespace after it
  defp close_tag_remove_whitespace do
    string("-%}")
    |> Literal.whitespace()
  end

  defp boolean_expression(combinator \\ empty()) do
    operator =
      choice([
        string("=="),
        string("!="),
        string(">="),
        string("<="),
        string(">"),
        string("<"),
        string("contains")
      ])
      |> map({String, :to_atom, []})

    boolean_operator =
      choice([
        replace(string("and"), :and),
        replace(string("or"), :or)
      ])

    boolean_operation =
      tag(Argument.argument(), :left)
      |> ignore(Literal.whitespace())
      |> unwrap_and_tag(operator, :op)
      |> ignore(Literal.whitespace())
      |> tag(Argument.argument(), :right)
      |> wrap()

    combinator
    |> choice([boolean_operation, Literal.literal(), Argument.argument()])
    |> ignore(Literal.whitespace())
    |> repeat(
      boolean_operator
      |> ignore(Literal.whitespace())
      |> choice([boolean_operation, Literal.literal(), Argument.argument()])
      |> ignore(Literal.whitespace())
    )
  end
end
