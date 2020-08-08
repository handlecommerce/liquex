defmodule Liquex.Context do
  @moduledoc """
  Stores contextual information for the parser
  """

  @type error_mode_t :: :lax | :warn | :strict
  defstruct variables: %{},
            cycles: %{},
            private: %{},
            filter_module: Liquex.Filter,
            render_module: nil,
            errors: []

  @type t :: %__MODULE__{
          variables: map(),
          cycles: map(),
          private: map(),
          filter_module: module,
          render_module: module | nil,
          errors: list(LiquexError.t())
        }

  @spec new(map()) :: t()
  @doc """
  Create a new `Context.t` using predefined `variables` map

  Returns a new, initialized context object
  """
  def new(variables), do: %__MODULE__{variables: variables}

  @spec assign(t(), String.t(), any) :: t()
  @doc """
  Assign a new variable to the `context`

  Set a variable named `key` with the given `value` in the current context
  """
  def assign(%__MODULE__{variables: variables} = context, key, value) do
    updated_variables = Map.put(variables, key, value)
    %{context | variables: updated_variables}
  end

  @spec push_error(t(), struct) :: t()
  @doc """
  Assign an error to the error logs
  """
  def push_error(%__MODULE__{errors: errors} = context, error),
    do: %{context | errors: [error | errors]}
end
