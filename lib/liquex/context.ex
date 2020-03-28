defmodule Liquex.Context do
  @moduledoc """
  Stores contextual information for the parser
  """

  defstruct variables: %{}, cycles: %{}, filter_module: Liquex.Filter

  @type t :: %__MODULE__{
          variables: %{String.t() => any},
          cycles: %{any => pos_integer},
          filter_module: module
        }

  @spec new(map()) :: t()
  def new(variables), do: %__MODULE__{variables: variables}

  @spec assign(t(), any, any) :: t()
  def assign(%__MODULE__{variables: variables} = context, key, value) do
    %{context | variables: variables |> Map.put(key, value)}
  end
end
