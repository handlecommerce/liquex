defmodule Liquex.Parser.Tag.Comment do
  @behaviour Liquex.Tag

  alias Liquex.Parser.Tag

  import NimbleParsec

  @impl true
  # Parse {% comment %}...{% endcomment %}
  @spec parse :: NimbleParsec.t()
  def parse() do
    empty()
    |> ignore(Tag.tag_directive("comment"))
    |> ignore(parsec(:document))
    |> ignore(Tag.tag_directive("endcomment"))
  end

  @impl true
  @spec render(Liquex.document_t(), Liquex.Context.t()) ::
          {iodata, Liquex.Context.t()} | iodata
  def render(_contents, context), do: {[], context}
end
