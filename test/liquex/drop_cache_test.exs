defmodule Liquex.DropCacheTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Liquex.Context

  defmodule CountingDrop do
    @moduledoc false
    @behaviour Liquex.Drop

    defstruct [:counter]

    @impl true
    def fetch(%__MODULE__{counter: counter}, key, _context)
        when key in ["name", :name, "title", :title] do
      Agent.update(counter, &(&1 + 1))
      {:ok, String.upcase(to_string(key))}
    end

    def fetch(_, _, _), do: :error
  end

  defmodule UncacheableDrop do
    @moduledoc false
    @behaviour Liquex.Drop

    defstruct [:counter]

    @impl true
    def fetch(%__MODULE__{counter: counter}, _key, _context) do
      Agent.update(counter, &(&1 + 1))
      {:ok, "result"}
    end

    @impl true
    def cacheable?(_drop), do: false
  end

  defmodule CategoryDrop do
    @moduledoc false
    @behaviour Liquex.Drop

    defstruct [:counter, :name]

    @impl true
    def fetch(%__MODULE__{counter: counter, name: name}, key, _context)
        when key in ["name", :name] do
      Agent.update(counter, &(&1 + 1))
      {:ok, name}
    end

    def fetch(_, _, _), do: :error
  end

  defmodule ProductDrop do
    @moduledoc false
    @behaviour Liquex.Drop

    defstruct [:counter, :category_counter, :category_name]

    @impl true
    def fetch(%__MODULE__{} = product, key, _context) when key in ["category", :category] do
      Agent.update(product.counter, &(&1 + 1))
      {:ok, %CategoryDrop{counter: product.category_counter, name: product.category_name}}
    end

    def fetch(_, _, _), do: :error
  end

  setup do
    {:ok, counter} = Agent.start_link(fn -> 0 end)
    %{counter: counter}
  end

  describe "per-render Drop caching" do
    test "the same drop accessed N times is fetched once", %{counter: counter} do
      drop = %CountingDrop{counter: counter}
      ctx = Context.new(%{"product" => drop})

      template = "{{ product.name }}-{{ product.name }}-{{ product.name }}"
      {:ok, ast} = Liquex.parse(template)
      {output, _} = Liquex.render!(ast, ctx)

      assert IO.iodata_to_binary(output) == "NAME-NAME-NAME"
      assert Agent.get(counter, & &1) == 1
    end

    test "chained drops cache at each level", %{counter: counter} do
      {:ok, category_counter} = Agent.start_link(fn -> 0 end)

      product = %ProductDrop{
        counter: counter,
        category_counter: category_counter,
        category_name: "Widgets"
      }

      ctx = Context.new(%{"product" => product})

      template =
        "{{ product.category.name }}|{{ product.category.name }}|{{ product.category.name }}"

      {:ok, ast} = Liquex.parse(template)
      {output, _} = Liquex.render!(ast, ctx)

      assert IO.iodata_to_binary(output) == "Widgets|Widgets|Widgets"

      # product.category fetched once across 3 references.
      assert Agent.get(counter, & &1) == 1
      # category.name fetched once across 3 references.
      assert Agent.get(category_counter, & &1) == 1
    end

    test "cacheable? returning false re-fetches every time", %{counter: counter} do
      drop = %UncacheableDrop{counter: counter}
      ctx = Context.new(%{"thing" => drop})

      template = "{{ thing.x }}-{{ thing.x }}-{{ thing.x }}"
      {:ok, ast} = Liquex.parse(template)
      {_output, _} = Liquex.render!(ast, ctx)

      assert Agent.get(counter, & &1) == 3
    end

    test "consecutive renders do not share cache", %{counter: counter} do
      drop = %CountingDrop{counter: counter}
      ctx = Context.new(%{"product" => drop})

      {:ok, ast} = Liquex.parse("{{ product.name }}{{ product.name }}")

      {_, _} = Liquex.render!(ast, ctx)
      {_, _} = Liquex.render!(ast, ctx)

      # 1 fetch per render * 2 renders = 2.
      assert Agent.get(counter, & &1) == 2
    end

    test "different drops do not collide", %{counter: counter} do
      drop_a = %CountingDrop{counter: counter}

      {:ok, second_counter} = Agent.start_link(fn -> 0 end)
      drop_b = %CountingDrop{counter: second_counter}

      ctx = Context.new(%{"a" => drop_a, "b" => drop_b})

      template = "{{ a.name }}{{ b.name }}{{ a.name }}{{ b.name }}"
      {:ok, ast} = Liquex.parse(template)
      {_, _} = Liquex.render!(ast, ctx)

      # Each drop fetched once despite two references each.
      assert Agent.get(counter, & &1) == 1
      assert Agent.get(second_counter, & &1) == 1
    end

    test "{% render %} partial inherits parent's drop cache", %{counter: counter} do
      drop = %CountingDrop{counter: counter}
      file_system = Liquex.MockFileSystem.new(%{"partial" => "{{ product.name }}"})

      ctx =
        Context.new(%{"product" => drop},
          file_system: file_system,
          static_environment: %{"product" => drop}
        )

      template = ~s({{ product.name }}-{% render "partial" %})
      {:ok, ast} = Liquex.parse(template)
      {_, _} = Liquex.render!(ast, ctx)

      # parent + partial reference the same drop; only one fetch.
      assert Agent.get(counter, & &1) == 1
    end
  end

  describe "drops with @behaviour Access (legacy)" do
    defmodule AccessOnlyDrop do
      @moduledoc false
      @behaviour Access

      defstruct [:counter]

      @impl true
      def fetch(%__MODULE__{counter: counter}, _key) do
        Agent.update(counter, &(&1 + 1))
        {:ok, "value"}
      end

      @impl true
      def get_and_update(c, _, _), do: {nil, c}
      @impl true
      def pop(c, _), do: {nil, c}
    end

    test "Access-only structs work but are not cached", %{counter: counter} do
      drop = %AccessOnlyDrop{counter: counter}
      ctx = Context.new(%{"x" => drop})

      template = "{{ x.foo }}{{ x.foo }}{{ x.foo }}"
      {:ok, ast} = Liquex.parse(template)
      {_, _} = Liquex.render!(ast, ctx)

      # Each reference re-fetches because the legacy Access path doesn't cache.
      assert Agent.get(counter, & &1) == 3
    end
  end
end
