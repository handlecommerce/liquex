defmodule Liquex.Custom.CustomFilterTest do
  @moduledoc false

  use ExUnit.Case, async: true
  alias Liquex.Context

  defmodule CustomFilterExample do
    @moduledoc false
    use Liquex.Filter

    def scream(value, _), do: String.upcase(value) <> "!"
  end

  # describe "custom filter" do
  #   test "adds a custom filter" do
  #     context = %Liquex.Context{filter_module: CustomFilterExample}

  #     {:ok, template} = Liquex.parse("{{'Hello World' | scream}}")

  #     assert template
  #            |> Liquex.render(context)
  #            |> elem(0)
  #            |> IO.chardata_to_string() == "HELLO WORLD!"
  #   end
  # end
end
