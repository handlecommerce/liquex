defmodule Liquex.Parser.Tag do
  @moduledoc false

  import NimbleParsec

  alias Liquex.Parser.Literal

  alias Liquex.Parser.Tag.{
    ControlFlow,
    Iteration,
    Variable
  }

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
        Iteration.continue_tag(),
        Iteration.tablerow_tag()
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
      variable_tags
    ])
  end

  # Close tag that also removes the whitespace after it
  defp close_tag_remove_whitespace do
    string("-%}")
    |> Literal.whitespace()
  end
end
