defmodule Liquex.Parser do
  @moduledoc """
  Liquid parser
  """

  import NimbleParsec

  alias Liquex.Parser.Base

  defcombinatorp(:document, repeat(Base.base_element()))
  defparsec(:parse, parsec(:document) |> eos())
end
