defmodule Liquex.Custom.CustomFilterTest do
  @moduledoc false

  use ExUnit.Case, async: true

  defmodule CustomFilterExample do
    @moduledoc false
    use Liquex.Filter

    def scream(value, _), do: String.upcase(value) <> "!"

    def img_url(path, size, [{"crop", direction}, {"filter", filter}], _),
      do: "https://example.com/#{path}?size=#{size}&crop=#{direction}&filter=#{filter}"
  end

  describe "custom filter" do
    test "adds a custom filter" do
      context = %Liquex.Context{filter_module: CustomFilterExample}

      {:ok, template} = Liquex.parse("{{'Hello World' | scream}}")

      assert template
             |> Liquex.render(context)
             |> elem(0)
             |> to_string() == "HELLO WORLD!"
    end

    test "handles keyword arguments" do
      context = %Liquex.Context{filter_module: CustomFilterExample}

      {:ok, template} =
        Liquex.parse("{{'image.jpg' | img_url: '400x400', crop: 'bottom', filter: 'blur'}}")

      assert template
             |> Liquex.render(context)
             |> elem(0)
             |> to_string() ==
               "https://example.com/image.jpg?size=400x400&crop=bottom&filter=blur"
    end
  end
end
