defmodule Liquex.Context do
  defstruct variables: %{}, cycles: %{}

  @type t :: %__MODULE__{
          variables: %{String.t() => any},
          cycles: %{any => pos_integer}
        }

  @spec new(map()) :: t()
  def new(variables), do: %__MODULE__{variables: variables}

  @spec assign(t(), any, any) :: t()
  def assign(%__MODULE__{variables: variables} = context, key, value) do
    %{context | variables: variables |> Map.put(key, value)}
  end
end
