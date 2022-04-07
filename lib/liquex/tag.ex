defmodule Liquex.Tag do
  @moduledoc """
  Behaviour for building a tag parser and renderer in Liquex.

  To build a custom tag, create a new module and imblement the `Liquex.Tag` behaviour.

      defmodule CustomTag do
        @behaviour Liquex.Tag

        import NimbleParsec

        @impl true
        # Parse <<Custom Tag>>
        def parse() do
          text =
            lookahead_not(string(">>"))
            |> utf8_char([])
            |> times(min: 1)
            |> reduce({Kernel, :to_string, []})
            |> tag(:text)

          combinator
          |> ignore(string("<<"))
          |> optional(text)
          |> ignore(string(">>"))
        end

        @impl true
        def render(contents, context) do
          {result, context} = Liquex.Render.render(contents, context)
          {["Custom Tag: ", result], context}
        end
      end

  You will then have to create a new parser to parse any custom tags.

      defmodule CustomParser do
        use Liquex.Parser, tags: [CustomTag, OtherTag]
      end

  From there, you can parse and render your liquid content.

      {:ok, document} = Liquex.parse("<<Hello World!>>", CustomParser)
      {result, _} = Liquex.render(document, context)

  """

  @doc """
  Returns a `NimbleParsec` expression to parse a tag.
  """
  @callback parse() :: NimbleParsec.t()

  @doc """
  Render the tag built by the parser defined in `parse/0`
  """
  @callback render(list(), Liquex.Context.t()) ::
              {iodata, Liquex.Context.t()}
              | {:break, iodata, Liquex.Context.t()}
              | {:continue, iodata, Liquex.Context.t()}
end
