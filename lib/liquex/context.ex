defmodule Liquex.Context do
  @moduledoc """
  Stores contextual information for the parser
  """

  @behaviour Access

  alias Liquex.Scope

  defstruct environment: %{},
            scope: nil,
            cycles: %{},
            private: %{},
            filter_module: Liquex.Filter,
            render_module: nil,
            file_system: nil,
            errors: []

  @type t :: %__MODULE__{
          environment: map(),
          scope: Scope.t(),
          cycles: map(),
          private: map(),
          filter_module: module,
          file_system: term() | nil,
          render_module: module | nil,
          errors: list(Liquex.Error.t())
        }

  alias Liquex.Indifferent

  @spec new(map(), Keyword.t()) :: t()
  @doc """
  Create a new `Context` using predefined `variables` map

  Returns a new, initialized context object
  """
  def new(environment, opts \\ []) do
    %__MODULE__{
      environment: environment,
      scope: Scope.new(Keyword.get(opts, :outer_scope, %{})),
      filter_module: Keyword.get(opts, :filter_module, Liquex.Filter),
      render_module: Keyword.get(opts, :render_module),
      file_system: Keyword.get(opts, :file_system, %Liquex.BlankFileSystem{})
    }
  end

  @spec assign(t(), String.t() | atom, any) :: t()
  @doc """
  Assign a new variable to the `context`

  Set a variable named `key` with the given `value` in the current context
  """
  def assign(%__MODULE__{scope: scope} = context, key, value),
    do: %{context | scope: Scope.assign(scope, key, value)}

  def assign_global(%__MODULE__{scope: scope} = context, key, value),
    do: %{context | scope: Scope.assign_global(scope, key, value)}

  def push_scope(%__MODULE__{} = context, new_scope \\ %{}),
    do: %{context | scope: Scope.push(context.scope, new_scope)}

  def pop_scope(%__MODULE__{} = context),
    do: %{context | scope: Scope.pop(context.scope)}

  @spec push_error(t(), struct) :: t()
  @doc """
  Assign an error to the error logs
  """
  def push_error(%__MODULE__{errors: errors} = context, error),
    do: %{context | errors: [error | errors]}

  def fetch(%__MODULE__{scope: scope, environment: environment}, key) do
    case Scope.fetch(scope, key) do
      {:ok, value} -> {:ok, value}
      _ -> Indifferent.fetch(environment, key)
    end
  end

  def get_and_update(%__MODULE__{} = context, key, function) do
    context
    |> Access.get(key, nil)
    |> function.()
    |> case do
      {current_value, new_value} -> {current_value, assign(context, key, new_value)}
      :pop -> Access.pop(context, key)
    end
  end

  def pop(%__MODULE__{} = context, key) do
    value = Access.get(context, key)
    {value, assign(context, key, nil)}
  end

  def get(%__MODULE__{} = context, key, default \\ nil) do
    case fetch(context, key) do
      {:ok, value} -> value
      _ -> default
    end
  end
end
