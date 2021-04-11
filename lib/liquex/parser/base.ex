defmodule Liquex.Parser.Base do
  @moduledoc false

  import NimbleParsec

  alias Liquex.Parser.{
    Literal,
    Object,
    Tag
  }

  @spec base_element(NimbleParsec.t()) :: NimbleParsec.t()
  def base_element(combinator \\ empty()) do
    combinator
    |> choice([Object.object(), Tag.tag(), Literal.text(), Literal.ignored_leading_whitespace()])
  end
end
