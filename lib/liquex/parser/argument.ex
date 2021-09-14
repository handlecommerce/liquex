defmodule Liquex.Parser.Argument do
  @moduledoc false

  import NimbleParsec

  alias Liquex.Parser.Argument.Helper

  @spec argument(NimbleParsec.t()) :: NimbleParsec.t()
  def argument(combinator \\ empty()),
    do: parsec(combinator, {Helper, :argument})
end

defmodule Liquex.Parser.Argument.Helper do
  @moduledoc false

  import NimbleParsec

  alias Liquex.Parser.Field
  alias Liquex.Parser.Literal

  defcombinator(:argument, choice([Literal.literal(), Field.field()]))
end
