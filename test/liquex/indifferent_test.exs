defmodule Liquex.IndifferentTest do
  @moduledoc false

  use ExUnit.Case, async: true

  defmodule TestNonAccessModule, do: defstruct([:x])

  doctest Liquex.Indifferent

  defmodule TestDrop do
    @moduledoc false
    use Liquex.Drop, cacheable: false

    defstruct []

    defliquid atom_test(_drop, _ctx), do: %{title: "Atom Test"}
    defliquid string_test(_drop, _ctx), do: %{title: "String Test"}
  end

  describe "drop dispatch" do
    test "resolves dynamic keys via the Liquex.Drop behaviour" do
      {:ok, template} =
        """
        {{ test['atom_test'].title }}!
        {{ test['string_test'].title }}!
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render!(template, %{test: %TestDrop{}})
             |> elem(0)
             |> to_string()
             |> String.trim() == "Atom Test!\nString Test!"
    end
  end
end
