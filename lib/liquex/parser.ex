defmodule Liquex.Parser do
  @moduledoc """
  Liquid base parser
  """

  import NimbleParsec
  alias Liquex.Parser.Base

  defcombinatorp(:document, repeat(Base.document()))
  defparsec(:parse, parsec(:document))
end
