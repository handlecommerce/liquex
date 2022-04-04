defmodule Liquex.Parser.Tag.Raw do
  @behaviour Liquex.Tag
  import NimbleParsec

  alias Liquex.Parser.Tag

  def parse() do
    endraw = Tag.tag_directive("endraw")

    text =
      lookahead_not(endraw)
      |> utf8_char([])
      |> times(min: 1)
      |> reduce({Kernel, :to_string, []})

    ignore(Tag.tag_directive("raw"))
    |> optional(text)
    |> ignore(endraw)
  end

  def render(contents, context), do: {contents, context}
end
