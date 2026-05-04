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

  describe "use Liquex.Drop + defliquid macro" do
    defmodule MacroDrop do
      @moduledoc false
      use Liquex.Drop

      defstruct [:counter, :name]

      defliquid title(drop, _ctx) do
        Agent.update(drop.counter, &(&1 + 1))
        String.upcase(drop.name)
      end

      defliquid raw_name(drop, _ctx), do: drop.name
    end

    defmodule CheapMacroDrop do
      @moduledoc false
      use Liquex.Drop, cacheable: false

      defstruct [:counter]

      defliquid x(drop, _ctx) do
        Agent.update(drop.counter, &(&1 + 1))
        :ok
      end
    end

    test "registered attributes dispatch to defliquid functions and are cached", %{
      counter: counter
    } do
      drop = %MacroDrop{counter: counter, name: "widget"}
      ctx = Context.new(%{"d" => drop})

      {:ok, ast} = Liquex.parse("{{ d.title }}-{{ d.title }}-{{ d.raw_name }}")
      {output, _} = Liquex.render!(ast, ctx)

      assert IO.iodata_to_binary(output) == "WIDGET-WIDGET-widget"
      # title is computed once across two references; raw_name has no Agent
      # update so the counter only reflects title invocations.
      assert Agent.get(counter, & &1) == 1
    end

    test "unregistered keys return :error", %{counter: counter} do
      drop = %MacroDrop{counter: counter, name: "widget"}
      ctx = Context.new(%{"d" => drop})

      {:ok, ast} = Liquex.parse("[{{ d.unknown }}]")
      {output, _} = Liquex.render!(ast, ctx)

      assert IO.iodata_to_binary(output) == "[]"
    end

    test "cacheable: false skips memoization", %{counter: counter} do
      drop = %CheapMacroDrop{counter: counter}
      ctx = Context.new(%{"d" => drop})

      {:ok, ast} = Liquex.parse("{{ d.x }}{{ d.x }}{{ d.x }}")
      {_, _} = Liquex.render!(ast, ctx)

      assert Agent.get(counter, & &1) == 3
    end

    test "cacheable: false sets Liquex.Drop.cacheable?/1 to false", %{counter: counter} do
      assert Liquex.Drop.cacheable?(%CheapMacroDrop{counter: counter}) == false
      assert Liquex.Drop.cacheable?(%MacroDrop{counter: counter, name: ""}) == true
    end
  end

  describe "plain structs (no Liquex.Drop)" do
    defmodule PlainStruct do
      @moduledoc false
      defstruct [:title, :count]
    end

    test "support direct field access for atom and string keys", %{counter: _counter} do
      ctx = Context.new(%{"thing" => %PlainStruct{title: "hi", count: 7}})

      {:ok, ast} = Liquex.parse("{{ thing.title }}-{{ thing.count }}")
      {output, _} = Liquex.render!(ast, ctx)

      assert IO.iodata_to_binary(output) == "hi-7"
    end

    test "unknown keys on plain structs render empty", %{counter: _counter} do
      ctx = Context.new(%{"thing" => %PlainStruct{title: "hi"}})

      {:ok, ast} = Liquex.parse("[{{ thing.unknown }}]")
      {output, _} = Liquex.render!(ast, ctx)

      assert IO.iodata_to_binary(output) == "[]"
    end
  end
end
