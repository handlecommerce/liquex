defmodule Liquex.Custom.CustomTagTest do
  @moduledoc false

  use ExUnit.Case, async: true

  defmodule CustomTagExample do
    @moduledoc false

    import NimbleParsec
    alias Liquex.Parser.Base

    # Parse <<Custom Tag>>
    def custom_tag(combinator \\ empty()) do
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
      |> tag(:custom_tag)
    end

    def element(combinator \\ empty()) do
      combinator
      |> choice([custom_tag(), Base.base_element()])
    end
  end

  defmodule CustomParser do
    @moduledoc false
    import NimbleParsec

    defcombinatorp(:document, repeat(CustomTagExample.element()))
    defparsec(:parse, parsec(:document) |> eos())
  end

  defmodule CustomRenderer do
    def render({:custom_tag, contents}, context) do
      {result, context} = Liquex.render(contents, context)

      {:ok, ["Custom Tag: ", result], context}
    end

    def render(_, _), do: :ignore
  end

  describe "custom tag" do
    test "adds a custom tag" do
      {:ok, template} = Liquex.parse("<<Hello World!>>{{ variable }}", CustomParser)

      assert [
               {:custom_tag, [text: ["Hello World!"]]},
               {:object, [field: [key: "variable"], filters: []]}
             ] == template

      assert elem(Liquex.render(template, %Liquex.Context{render_module: CustomRenderer}), 0)
             |> IO.chardata_to_string()
             |> String.trim() == "Custom Tag: Hello World!"
    end
  end
end
