defmodule Liquex.Custom.CustomFilterTest do
  @moduledoc false

  use ExUnit.Case, async: true

  describe "custom filter" do
    test "adds a custom filter" do
      {:ok, template} = Liquex.parse("{{'Hello World' | scream}}")

      assert template
             |> Liquex.render()
             |> elem(0)
             |> IO.chardata_to_string() == "HELLO WORLD!"
    end
  end
end
