defmodule Liquex.IndifferentTest do
  @moduledoc false

  use ExUnit.Case, async: true

  defmodule TestAccessModule do
    @behaviour Access

    defstruct []

    def fetch(_container, :atom_test), do: {:ok, %{title: "Atom Test"}}
    def fetch(_container, "string_test"), do: {:ok, %{title: "String Test"}}
    def fetch(_, _), do: :error

    def pop(container, _key), do: {nil, container}

    def get_and_update(container, _key, _func), do: {nil, container}
  end

  defmodule TestNonAccessModule, do: defstruct([:x])

  doctest Liquex.Indifferent

  describe "access behaviour" do
    test "allows lazy access to Access implementing modules" do
      {:ok, template} =
        """
        {{ test['atom_test'].title }}!
        {{ test['string_test'].title }}!
        """
        |> String.trim()
        |> Liquex.parse()

      assert Liquex.render(template, %{test: %TestAccessModule{}})
             |> elem(0)
             |> to_string()
             |> String.trim() == "Atom Test!\nString Test!"
    end
  end
end
