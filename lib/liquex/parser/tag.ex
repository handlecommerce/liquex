defmodule Liquex.Parser.Tag do
  import NimbleParsec

  alias Liquex.Parser.Literal

  alias Liquex.Parser.Tag.{
    ControlFlow,
    Iteration,
    Variable
  }

  @spec tag_directive(NimbleParsec.t(), String.t()) :: NimbleParsec.t()
  def tag_directive(combinator \\ empty(), name) do
    combinator
    |> string("{%")
    |> Literal.whitespace()
    |> string(name)
    |> Literal.whitespace()
    |> string("%}")
  end

  @spec comment_tag(NimbleParsec.t()) :: NimbleParsec.t()
  def comment_tag(combinator \\ empty()) do
    combinator
    |> ignore(tag_directive("comment"))
    |> ignore(parsec(:document))
    |> ignore(tag_directive("endcomment"))
  end

  def raw_tag(combinator \\ empty()) do
    endraw = tag_directive("endraw") |> wrap()

    text =
      lookahead_not(endraw)
      |> utf8_char([])
      |> times(min: 1)
      |> reduce({Kernel, :to_string, []})
      |> tag(:text)
      |> label("raw content followed by {% endraw %}")

    combinator
    |> ignore(tag_directive("raw"))
    |> optional(text)
    |> ignore(endraw)
  end

  @spec tag(NimbleParsec.t()) :: NimbleParsec.t()
  def tag(combinator \\ empty()) do
    control_flow_tags =
      choice([
        ControlFlow.if_expression(),
        ControlFlow.unless_expression(),
        ControlFlow.case_expression()
      ])
      |> tag(:control_flow)

    iteration_tags =
      choice([
        Iteration.for_expression(),
        Iteration.cycle_tag(),
        Iteration.break_tag(),
        Iteration.continue_tag()
      ])
      |> tag(:iteration)

    variable_tags =
      choice([
        Variable.assign_tag(),
        Variable.capture_tag(),
        Variable.incrementer_tag()
      ])
      |> tag(:variable)

    combinator
    |> choice([
      control_flow_tags,
      iteration_tags,
      variable_tags,
      raw_tag(),
      comment_tag()
    ])
  end
end
