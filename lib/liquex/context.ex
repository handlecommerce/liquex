defmodule Liquex.Context do
  @moduledoc """
  Stores contextual information for the parser
  """

  defstruct variables: %{}, cycles: %{}, filter_module: Liquex.Filter

  @type t :: %__MODULE__{
          variables: map(),
          cycles: map(),
          filter_module: module
        }

  @spec new(map()) :: t()
  def new(variables), do: %__MODULE__{variables: variables}

  @spec assign(t(), String.t(), any) :: t()
  def assign(%__MODULE__{variables: variables} = context, key, value) do
    updated_variables = Map.put(variables, key, value)
    %{context | variables: updated_variables}
  end
end
