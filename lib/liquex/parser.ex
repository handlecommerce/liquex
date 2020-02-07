defmodule Liquex.Parser do
  @moduledoc """
  Liquid base parser
  """

  import NimbleParsec

  alias Liquex.Parser.Object
  alias Liquex.Parser.Tag

  text =
    lookahead_not(choice([string("{{"), string("{%")]))
    |> utf8_char([])
    |> times(min: 1)
    |> reduce({Kernel, :to_string, []})
    |> unwrap_and_tag(:text)

  defcombinatorp(
    :document,
    repeat(choice([Object.object(), Tag.tag(), text]))
  )

  defparsec(:parse, parsec(:document))
end
