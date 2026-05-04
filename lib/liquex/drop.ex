defmodule Liquex.Drop do
  @moduledoc """
  Behaviour for context-aware indifferent-access "drops".

  A drop is a struct whose module declares `@behaviour Liquex.Drop` and
  implements `fetch/3`. Liquex's resolver dispatches `.` traversals
  (`{{ products.first.category.name }}`) through `fetch/3`, passing the
  current `Liquex.Context` so the drop can:

    * Read `context.cache_prefix`, `context.private`, or other variables
      while resolving its own fields.
    * Have its results automatically memoized for the duration of a single
      render — repeat references to the same `{drop, key}` pair within one
      `Liquex.render!/2` call only invoke `fetch/3` once.

  Existing structs that implement `@behaviour Access` still work unchanged
  — they fall through the legacy uncached path. Switching from `Access`
  to `Liquex.Drop` is the way to opt in to per-render memoization.

  ## Example

      defmodule MyApp.ProductsDrop do
        @behaviour Liquex.Drop
        defstruct [:scope]

        @impl true
        def fetch(%__MODULE__{scope: scope}, key, _context) when key in ["first", :first] do
          {:ok, MyApp.Repo.one(from p in scope, limit: 1)}
        end

        def fetch(%__MODULE__{scope: scope}, key, _context) when key in ["all", :all] do
          {:ok, MyApp.Repo.all(scope)}
        end

        def fetch(_, _, _), do: :error
      end

  ## Opting out of memoization

  Stateful drops (paginators, generators) that should re-run on every access
  can opt out by implementing `cacheable?/1`:

      def cacheable?(_drop), do: false

  Default is `true` when the callback is absent.
  """

  @type key :: any()

  @doc """
  Resolve `key` against `drop` for the given render `context`.

  Returns `{:ok, value}` on success or `:error` to signal "no such key" — the
  resolver will then try string/atom alternates and finally produce `nil`.
  """
  @callback fetch(drop :: struct(), key(), Liquex.Context.t()) :: {:ok, any()} | :error

  @doc """
  Whether results from `fetch/3` should be memoized for the rest of the
  current render. Defaults to `true` when not implemented.
  """
  @callback cacheable?(drop :: struct()) :: boolean()

  @optional_callbacks [cacheable?: 1]

  @doc """
  Whether the given struct's module is registered as a `Liquex.Drop`.
  """
  @spec drop?(any()) :: boolean()
  def drop?(value) when is_struct(value) do
    module = value.__struct__
    Code.ensure_loaded?(module) and function_exported?(module, :fetch, 3) and
      __MODULE__ in (module.module_info(:attributes) |> Keyword.get(:behaviour, []))
  end

  def drop?(_), do: false

  @doc """
  Whether `drop`'s module wants its `fetch/3` results cached. Defaults to
  `true` when the optional `cacheable?/1` callback isn't defined.
  """
  @spec cacheable?(struct()) :: boolean()
  def cacheable?(drop) when is_struct(drop) do
    module = drop.__struct__

    if function_exported?(module, :cacheable?, 1) do
      module.cacheable?(drop)
    else
      true
    end
  end
end
