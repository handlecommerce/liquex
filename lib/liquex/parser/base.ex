defmodule Liquex.Parser.Base do
  @moduledoc """
  Contains base implementation for Liquid parser
  """

  import NimbleParsec

  alias Liquex.Parser.Object
  alias Liquex.Parser.Tag

  def text(combinator \\ empty()) do
    combinator
    |> lookahead_not(choice([string("{{"), string("{%")]))
    |> utf8_char([])
    |> times(min: 1)
    |> reduce({Kernel, :to_string, []})
    |> unwrap_and_tag(:text)
  end

  def document(combinator \\ empty()) do
    combinator
    |> choice([Object.object(), Tag.tag(), text()])
  end
end
