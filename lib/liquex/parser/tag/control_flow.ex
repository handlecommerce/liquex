defmodule Liquex.Parser.Tag.ControlFlow do
  @moduledoc false

  import NimbleParsec

  alias Liquex.Parser.Argument
  alias Liquex.Parser.Literal
  alias Liquex.Parser.Tag

  @spec boolean_expression(NimbleParsec.t()) :: NimbleParsec.t()
  def boolean_expression(combinator \\ empty()) do
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

  @spec if_expression(NimbleParsec.t()) :: NimbleParsec.t()
  def if_expression(combinator \\ empty()) do
    if_tag =
      expression_tag("if")
      |> tag(parsec(:document), :contents)

    combinator
    |> tag(if_tag, :if)
    |> repeat(elsif_tag())
    |> optional(else_tag())
    |> ignore(Tag.tag_directive("endif"))
  end

  @spec unless_expression(NimbleParsec.t()) :: NimbleParsec.t()
  def unless_expression(combinator \\ empty()) do
    combinator
    |> expression_tag("unless")
    |> tag(parsec(:document), :contents)
    |> tag(:unless)
    |> repeat(elsif_tag())
    |> optional(else_tag())
    |> ignore(Tag.tag_directive("endunless"))
  end

  @spec case_expression(NimbleParsec.t()) :: NimbleParsec.t()
  def case_expression(combinator \\ empty()) do
    when_tag =
      ignore(Tag.open_tag())
      |> ignore(string("when"))
      |> ignore(Literal.whitespace(empty(), 1))
      |> tag(
        Literal.literal()
        |> repeat(
          ignore(string(","))
          |> ignore(Literal.whitespace(empty(), 1))
          |> Literal.literal()
        ),
        :expression
      )
      |> ignore(Tag.close_tag())
      |> tag(parsec(:document), :contents)

    case_tag =
      ignore(Tag.open_tag())
      |> ignore(string("case"))
      |> ignore(Literal.whitespace(empty(), 1))
      |> concat(Argument.argument())
      |> ignore(Tag.close_tag())

    combinator
    |> tag(case_tag, :case)
    |> ignore(Literal.whitespace())
    |> times(tag(when_tag, :when), min: 1)
    |> optional(else_tag())
    |> ignore(Tag.tag_directive("endcase"))
  end

  @spec else_tag(NimbleParsec.t()) :: NimbleParsec.t()
  def else_tag(combinator \\ empty()) do
    combinator
    |> ignore(Tag.tag_directive("else"))
    |> tag(parsec(:document), :contents)
    |> tag(:else)
  end

  defp elsif_tag(combinator \\ empty()) do
    combinator
    |> expression_tag("elsif")
    |> tag(parsec(:document), :contents)
    |> tag(:elsif)
  end

  @spec expression_tag(NimbleParsec.t(), String.t()) :: NimbleParsec.t()
  defp expression_tag(combinator \\ empty(), tag_name) do
    combinator
    |> ignore(Tag.open_tag())
    |> ignore(string(tag_name))
    |> ignore(Literal.whitespace())
    |> tag(boolean_expression(), :expression)
    |> ignore(Tag.close_tag())
  end
end
