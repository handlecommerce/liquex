defmodule Liquex.Custom.CustomTagTest do
  @moduledoc false
  use ExUnit.Case, async: true

  defmodule CustomTag do
    @moduledoc false

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

      ignore(string("<<"))
      |> optional(text)
      |> ignore(string(">>"))
    end

    @impl true
    def render(contents, context) do
      {result, _context} = Liquex.render(contents, context)
      ["Custom Tag: ", result]
    end
  end

  defmodule CustomParser do
    use Liquex.Parser, tags: [CustomTag]
  end

  describe "custom tag" do
    test "adds a custom tag" do
      {:ok, template} = Liquex.parse("<<Hello World!>>", CustomParser)

      assert [
               {{:tag, CustomTag}, [text: ["Hello World!"]]}
             ] == template

      assert elem(Liquex.render(template), 0)
             |> to_string()
             |> String.trim() == "Custom Tag: Hello World!"
    end
  end
end
