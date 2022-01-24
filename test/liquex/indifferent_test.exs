defmodule Liquex.IndifferentTest do
  @moduledoc false

  use ExUnit.Case, async: true

  defmodule StructWithAccess do
    @behaviour Access

    defstruct [:key]

    def fetch(container, :key) do
      {:ok, container.key <> " World"}
    end

    def fetch(_container, _), do: :error

    def pop(container, _key), do: {container.key, container}

    def get_and_update(container, _key, func),
      do: {container.key, %{container | key: func.(container.key)}}
  end

  doctest Liquex.Indifferent
end
