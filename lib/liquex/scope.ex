defmodule Liquex.Scope do
  @moduledoc false

  defstruct stack: []

  alias Liquex.Indifferent

  @type t :: %__MODULE__{
          stack: nonempty_list(map)
        }

  @spec new(map | nil) :: t()
  def new(outer_scope \\ %{}), do: %__MODULE__{stack: [outer_scope]}

  @spec push(Liquex.Scope.t(), any) :: Liquex.Scope.t()
  def push(%__MODULE__{stack: stack} = scope, new_scope \\ %{}),
    do: %{scope | stack: [new_scope | stack]}

  def pop(%__MODULE__{stack: [_ | []]} = scope), do: %{scope | stack: [%{}]}
  def pop(%__MODULE__{stack: [_ | tail]} = scope), do: %{scope | stack: tail}

  def assign_global(%__MODULE__{stack: stack} = scope, key, value) do
    namespace =
      stack
      |> List.last()
      |> Indifferent.put(key, value)

    %{scope | stack: List.replace_at(stack, -1, namespace)}
  end

  def assign(%__MODULE__{stack: stack} = scope, key, value),
    do: do_assign([], scope, stack, key, value)

  defp do_assign(_acc, %{stack: [head | rest]} = scope, [], key, value) do
    stack = [Indifferent.put(head, key, value) | rest]
    %{scope | stack: stack}
  end

  defp do_assign(acc, scope, [head | tail], key, value) do
    if Indifferent.has_key?(head, key) do
      stack = [Indifferent.put(head, key, value) | tail]
      %{scope | stack: Enum.reverse(acc) ++ stack}
    else
      do_assign([head | acc], scope, tail, key, value)
    end
  end

  def fetch(%__MODULE__{stack: stack}, key), do: do_fetch(stack, key)

  defp do_fetch([], _), do: :error

  defp do_fetch([scope | tail], key) do
    case Indifferent.fetch(scope, key) do
      :error -> do_fetch(tail, key)
      result -> result
    end
  end
end
