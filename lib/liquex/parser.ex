defmodule Liquex.Parser do
  @moduledoc """
  Liquid base parser
  """

  import NimbleParsec

  alias Liquex.Parsers.Objects
  alias Liquex.Parsers.Tags

  text =
    lookahead_not(choice([string("{{"), string("{%")]))
    |> utf8_char([])
    |> times(min: 1)
    |> reduce({Kernel, :to_string, []})
    |> tag(:text)

  defcombinatorp(
    :document,
    repeat(choice([Objects.object(), Tags.tag(), text]))
  )

  defparsec(:parse, parsec(:document) |> eos, debug: true)
end
