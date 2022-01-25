defmodule Liquex.Context do
  @moduledoc """
  Stores contextual information for the parser
  """

  defstruct variables: %{},
            cycles: %{},
            for_loop_offsets: %{},
            tablerow_loop_offsets: %{},
            private: %{},
            filter_module: Liquex.Filter,
            render_module: nil,
            errors: []

  @type t :: %__MODULE__{
          variables: map(),
          cycles: map(),
          for_loop_offsets: map(),
          tablerow_loop_offsets: map(),
          private: map(),
          filter_module: module,
          render_module: module | nil,
          errors: list(Liquex.Error.t())
        }

  alias Liquex.Indifferent

  @spec new(map(), Keyword.t()) :: t()
  @doc """
  Create a new `Context` using predefined `variables` map

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

  @doc """
  receive the last offset for a for loop
  """
  def for_loop_offset(%__MODULE__{for_loop_offsets: offsets}, identifier) do
    offsets[identifier] || 0
  end

  def tablerow_loop_offset(%__MODULE__{tablerow_loop_offsets: offsets}, identifier) do
    offsets[identifier] || 0
  end

  @doc """
  increase the offset for a for loop
  """
  def for_loop_offset_inc(%__MODULE__{for_loop_offsets: offsets} = ctx, identifier) do
    %__MODULE__{ctx | for_loop_offsets: Map.update(offsets, identifier, 1, &(&1 + 1))}
  end

  def tablerow_loop_offset_inc(%__MODULE__{tablerow_loop_offsets: offsets} = ctx, identifier) do
    %__MODULE__{ctx | tablerow_loop_offsets: Map.update(offsets, identifier, 1, &(&1 + 1))}
  end
end
