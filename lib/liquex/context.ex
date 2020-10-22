defmodule Liquex.Context do
  @moduledoc """
  Stores contextual information for the parser
  """

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

  alias Liquex.Indifferent

  @spec new(map(), Keyword.t()) :: t()
  @doc """
  Create a new `Context.t` using predefined `variables` map

  Returns a new, initialized context object
  """
  def new(variables, opts \\ []) do
    %__MODULE__{
      variables: variables,
      filter_module: Keyword.get(opts, :filter_module, Liquex.Filter),
      render_module: Keyword.get(opts, :render_module)
    }
  end

  @spec assign(t(), String.t() | atom, any) :: t()
  @doc """
  Assign a new variable to the `context`

  Set a variable named `key` with the given `value` in the current context
  """
  def assign(%__MODULE__{} = context, key, value) when is_atom(key),
    do: assign(context, Atom.to_string(key), value)

  def assign(%__MODULE__{variables: variables} = context, key, value) do
    updated_variables = Indifferent.put(variables, key, value)
    %{context | variables: updated_variables}
  end

  @spec push_error(t(), struct) :: t()
  @doc """
  Assign an error to the error logs
  """
  def push_error(%__MODULE__{errors: errors} = context, error),
    do: %{context | errors: [error | errors]}
end
