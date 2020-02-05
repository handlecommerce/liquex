defmodule Liquex.Parser do
  @moduledoc """
  Liquid base parser
  """

  import NimbleParsec

  alias Liquex.Parser.Object
  alias Liquex.Parser.Tag
  alias Liquex.Parser.ConditionalBlock

  text =
    lookahead_not(choice([string("{{"), string("{%")]))
    |> utf8_char([])
    |> times(min: 1)
    |> reduce({Kernel, :to_string, []})
    |> tag(:text)

  defcombinatorp(
    :document,
    repeat(choice([Object.object(), Tag.tag(), ConditionalBlock.if_block(), text]))
  )

  defparsec(:parse, parsec(:document) |> eos(), debug: true)
end
