defmodule Liquex.Context do
  @moduledoc """
  Context keeps the variable stack and resolves variables, as well as keywords.
  It also keeps configuration information needed to render a Liquid template,
  such as filters and the file system.

  Variables are stored within a few different contexts which each have their own
  usage and meaning.

  ### :environment

  The environment stores the top level variables defined outside of the liquid
  templates. These are variables you want to predefine before rendering the
  templates. Note: these variables are not accessible within nested `render` tags.

  ### :static_environment

  The static environment is similar to the base environment. The difference is
  that it has a lower priority for reading than the environment and the
  variables defined in this context are accessible within nested `render` tags.

  Use the static environment if you want global variables accessible across all
  render tags.

  ### :scope

  The scope is a stack of environments that keep track of variables within
  various scopes. For example, when entering a for loop, it creates a new scope
  and pushes it onto the stack. When exiting the for loop, all variables defined
  within that scope are removed.

  Scopes have the highest precedence of all the different locations that store
  variables.

  ## Examples

      iex> context = Liquex.Context.new(%{hello: "environment"})
      iex> Access.get(context, "hello")
      "environment"

      iex> context = Liquex.Context.new(%{}, scope: %{hello: "scope"})
      iex> Access.get(context, "hello")
      "scope"

      iex> context = Liquex.Context.new(%{}, static_environment: %{hello: "static environment"})
      iex> Access.get(context, "hello")
      "static environment"
  """

  @behaviour Access

  alias Liquex.Scope

  defstruct environment: %{},
            static_environment: %{},
            scope: nil,
            cycles: %{},
            private: %{},
            filter_module: Liquex.Filter,
            file_system: nil,
            errors: [],
            cache: nil,
            cache_prefix: nil

  @type t :: %__MODULE__{
          environment: map(),
          static_environment: map(),
          scope: Scope.t(),
          cycles: map(),
          private: map(),
          filter_module: module,
          file_system: struct,
          cache: term,
          cache_prefix: String.t(),
          errors: list(Liquex.Error.t())
        }

  alias Liquex.Indifferent

  @doc """
  Create a new `Context` using predefined `variables` map

  Returns a new context to store the current state of a liquid template during
  the render phase.

  ## Options

    * :static_environment - An unchanging environment scope also accessible from
      nested render tags.

    * :scope - Initial scope with variables defined as if they were set
      within the liquid template.

    * :filter_module - Module that will be used for filtering

    * :file_system - File loading module

    * :cache_prefix - Prefix for cache keys, if you need separate partial caches
      for multitenancy or otherwise
  """
  @spec new(map(), Keyword.t()) :: t()
  def new(environment, opts \\ []) do
    %__MODULE__{
      environment: environment,
      static_environment: Keyword.get(opts, :static_environment, %{}),
      scope: Scope.new(Keyword.get(opts, :scope, %{})),
      filter_module: Keyword.get(opts, :filter_module, Liquex.Filter),
      file_system: Keyword.get(opts, :file_system, %Liquex.BlankFileSystem{}),
      cache: Keyword.get(opts, :cache, Liquex.Cache.DisabledCache),
      cache_prefix: Keyword.get(opts, :cache_prefix, nil)
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

  @spec push_scope(t(), map) :: t()
  @doc """
  Push a new scope onto the scope stack
  """
  def push_scope(%__MODULE__{} = context, new_scope \\ %{}),
    do: %{context | scope: Scope.push(context.scope, new_scope)}

  @spec pop_scope(t()) :: t()
  @doc """
  Pop the current scope off the scope stack and throw it away
  """
  def pop_scope(%__MODULE__{} = context),
    do: %{context | scope: Scope.pop(context.scope)}

  @spec push_error(t(), struct) :: t()
  @doc """
  Assign an error to the error logs
  """
  def push_error(%__MODULE__{errors: errors} = context, error),
    do: %{context | errors: [error | errors]}

  @doc """
  Look up variable within the current scope. If the scope does not define the
  variable, it is then looked up in the environment. Lastly, if that fails, it
  falls back to the static environment.

  All variable look ups are indifferent to the key being a string or an atom.
  Either or can be used to save and store the variables.
  """
  @spec fetch(t(), any) :: :error | {:ok, any}
  def fetch(
        %__MODULE__{
          scope: scope,
          environment: environment,
          static_environment: static_environment
        },
        key
      ) do
    case Scope.fetch(scope, key) do
      {:ok, value} ->
        {:ok, value}

      _ ->
        # Try pulling from the top environment
        case Indifferent.fetch(environment, key) do
          {:ok, value} -> {:ok, value}
          # Try pulling from the static environment
          _ -> Indifferent.fetch(static_environment, key)
        end
    end
  end

  @spec get_and_update(t(), any, (any -> any)) :: {any, keyword | map}
  def get_and_update(%__MODULE__{} = context, key, function) do
    context
    |> Access.get(key, nil)
    |> function.()
    |> case do
      {current_value, new_value} -> {current_value, assign(context, key, new_value)}
      :pop -> Access.pop(context, key)
    end
  end

  @spec pop(t(), atom | binary) :: {any, t()}
  def pop(%__MODULE__{} = context, key) do
    value = Access.get(context, key)
    {value, assign(context, key, nil)}
  end

  @spec get(Liquex.Context.t(), any, any) :: any
  def get(%__MODULE__{} = context, key, default \\ nil) do
    case fetch(context, key) do
      {:ok, value} -> value
      _ -> default
    end
  end

  @doc """
  Create a new context inheriting static environment and options
  """
  @spec new_isolated_subscope(t(), map) :: t()
  def new_isolated_subscope(%__MODULE__{} = context, environment \\ %{}) do
    new(environment,
      static_environment: context.static_environment,
      filter_module: context.filter_module,
      file_system: context.file_system
    )
  end
end
