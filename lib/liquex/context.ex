defmodule Liquex.Context do
  defstruct variables: %{}, cycles: %{}

  @type t :: %__MODULE__{
          variables: map(),
          cycles: map()
        }

  def new(variables), do: %__MODULE__{variables: variables}

  def assign(%__MODULE__{variables: variables} = context, key, value) do
    %{context | variables: variables |> Map.put(key, value)}
  end
end
