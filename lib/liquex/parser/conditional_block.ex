defmodule Liquex.Parser.ConditionalBlock do
  import NimbleParsec

  alias Liquex.Parser.Object
  alias Liquex.Parser.Literal

  def operator(combinator \\ empty()) do
    combinator
    |> choice([
      string("=="),
      string("!="),
      string(">="),
      string("<="),
      string(">"),
      string("<"),
      string("contains")
    ])
    |> map({String, :to_existing_atom, []})
  end

  def boolean_operator(combinator \\ empty()) do
    combinator
    |> choice([
      replace(string("and"), :and),
      replace(string("or"), :or)
    ])
  end

  def boolean_operation(combinator \\ empty()) do
    combinator
    |> tag(Object.argument(), :left)
    |> ignore(Literal.whitespace())
    |> unwrap_and_tag(operator(), :op)
    |> ignore(Literal.whitespace())
    |> tag(Object.argument(), :right)
    |> wrap()
  end

  @spec boolean_expression(NimbleParsec.t()) :: NimbleParsec.t()
  def boolean_expression(combinator \\ empty()) do
    combinator
    |> choice([boolean_operation(), Literal.literal()])
    |> ignore(Literal.whitespace())
    |> repeat(
      boolean_operator()
      |> ignore(Literal.whitespace())
      |> choice([boolean_operation(), Literal.literal()])
    )
  end

  @spec if_tag(NimbleParsec.t()) :: NimbleParsec.t()
  def if_tag(combinator \\ empty()) do
    combinator
    |> ignore(string("{%"))
    |> ignore(Literal.whitespace())
    |> ignore(string("if"))
    |> ignore(Literal.whitespace())
    |> tag(boolean_expression(), :expression)
    |> ignore(Literal.whitespace())
    |> ignore(string("%}"))
    |> tag(parsec(:document), :contents)
  end

  def if_block(combinator \\ empty()) do
    combinator
    |> tag(if_tag(), :if)
    |> ignore(string("{%"))
    |> ignore(Literal.whitespace())
    |> ignore(string("endif"))
    |> ignore(Literal.whitespace())
    |> ignore(string("%}"))
  end
end
