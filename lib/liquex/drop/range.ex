defmodule Liquex.Drop.Range do
  @moduledoc false
  # Drop dispatch for stdlib `Range`. Templates read `.first`, `.last`,
  # and `.size`; native struct fields (`first`, `last`, `step`) fall
  # through Map.fetch via the resolver's atom/string retry.
  #
  # Range isn't ours to extend, so the resolver matches `%Range{}` in
  # `Liquex.Indifferent.attempt/3` and dispatches here by name. The
  # behaviour declaration documents the contract this module implements.

  @behaviour Liquex.Drop

  @impl Liquex.Drop
  def fetch(%Range{} = r, key, _ctx) do
    case key do
      "size" -> {:ok, Enum.count(r)}
      "first" -> {:ok, r.first}
      "last" -> {:ok, r.last}
      _ -> Map.fetch(r, key)
    end
  end
end
