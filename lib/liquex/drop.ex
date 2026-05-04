defmodule Liquex.Drop do
  @moduledoc """
  Behaviour for context-aware indifferent-access "drops".

  A drop is a struct whose module declares `@behaviour Liquex.Drop` (or
  `use Liquex.Drop`) and exposes attributes via `fetch/3`. Liquex's resolver
  dispatches `.` traversals (`{{ products.first.category.name }}`) through
  `fetch/3`, passing the current `Liquex.Context` so the drop can:

    * Read `context.cache_prefix`, `context.private`, or other variables
      while resolving its own fields.
    * Have its results automatically memoized for the duration of a single
      render — repeat references to the same `{drop, key}` pair within one
      `Liquex.render!/2` call only invoke `fetch/3` once.

  Plain structs without `@behaviour Liquex.Drop` are still readable from
  templates via direct field access (atom or string keys), but they cannot
  resolve dynamic keys, run computations on access, or participate in the
  per-render cache.

  ## Two ways to define a drop

  ### `use Liquex.Drop` + `defliquid` (recommended)

  Authors declare exposed attributes as regular functions; `fetch/3` is
  generated for them, restricted to the declared whitelist. Functions are
  also directly callable from Elixir (`MyDrop.index(drop, ctx)`).

      defmodule MyApp.ForloopDrop do
        use Liquex.Drop, cacheable: false

        defstruct [:index, :length]

        defliquid index(drop, _ctx),  do: drop.index + 1
        defliquid index0(drop, _ctx), do: drop.index
        defliquid first(drop, _ctx),  do: drop.index == 0
        defliquid last(drop, _ctx),   do: drop.index == drop.length - 1
      end

  Pass `cacheable: false` for drops whose attributes are cheap pure
  computations on struct fields — caching just bloats the per-render cache
  with values that are faster to recompute than to look up.

  ### Manual `@behaviour` (escape hatch)

  When you need full control over dispatch (custom error semantics, dynamic
  attribute lists, atom-key fallbacks, etc.), implement the behaviour by hand:

      defmodule MyApp.ProductsDrop do
        @behaviour Liquex.Drop
        defstruct [:scope]

        @impl true
        def fetch(%__MODULE__{scope: scope}, key, _context)
            when key in ["first", :first] do
          {:ok, MyApp.Repo.one(from p in scope, limit: 1)}
        end

        def fetch(_, _, _), do: :error
      end

  ## Opting out of memoization

  Stateful drops (paginators, generators) or drops whose attributes are
  cheaper to recompute than to cache should opt out:

      def cacheable?(_drop), do: false

  Or via `use Liquex.Drop, cacheable: false`. Default is `true` when
  `cacheable?/1` is not defined.
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

  defmacro __using__(opts) do
    cacheable = Keyword.get(opts, :cacheable, true)

    quote do
      @behaviour Liquex.Drop

      import Liquex.Drop, only: [defliquid: 2]

      Module.register_attribute(__MODULE__, :liquid_attributes, accumulate: true)

      @before_compile Liquex.Drop

      unless unquote(cacheable) do
        @impl Liquex.Drop
        def cacheable?(_), do: false
      end
    end
  end

  @doc """
  Define a drop attribute.

  Accepts a normal function head — `defliquid name(drop, ctx), do: …` — and
  registers `name` as an exposed attribute. The framework's auto-generated
  `fetch/3` will dispatch the string key `"name"` to this function. The
  function is also a regular public function on the module.
  """
  defmacro defliquid(call, do: body) do
    {name, _meta, _args} = call

    quote do
      @liquid_attributes unquote(name)
      def unquote(call), do: unquote(body)
    end
  end

  defmacro __before_compile__(env) do
    attrs =
      env.module
      |> Module.get_attribute(:liquid_attributes, [])
      |> Enum.uniq()

    fetch_clauses =
      Enum.map(attrs, fn name ->
        key_str = Atom.to_string(name)

        quote do
          def fetch(%__MODULE__{} = drop, unquote(key_str), context),
            do: {:ok, unquote(name)(drop, context)}
        end
      end)

    quote do
      @impl Liquex.Drop
      (unquote_splicing(fetch_clauses))
      def fetch(_, _, _), do: :error
    end
  end
end
