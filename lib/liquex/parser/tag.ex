defmodule Liquex.Parser.Tag do
  import NimbleParsec

  alias Liquex.Parser.Literal

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

    combinator
    |> ignore(tag_directive("raw"))
    |> optional(
      repeat(
        lookahead_not(endraw)
        |> utf8_string([], 1)
      )
      |> reduce({Enum, :join, []})
      |> tag(:text)
    )
    |> ignore(endraw)
  end

  @spec tag(NimbleParsec.t()) :: NimbleParsec.t()
  def tag(combinator \\ empty()) do
    combinator
    |> choice([
      comment_tag(),
      raw_tag()
    ])
  end
end
