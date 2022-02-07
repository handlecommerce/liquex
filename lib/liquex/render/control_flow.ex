defmodule Liquex.Render.ControlFlow do
  @moduledoc false

  alias Liquex.Argument
  alias Liquex.Expression

  @behaviour Liquex.Render

  @impl Liquex.Render
  def render({:control_flow, tag}, context), do: do_render(tag, context)
  def render(_, _), do: false

  defp do_render(list, context, match \\ nil)

  defp do_render([{tag, [expression: expression, contents: contents]} | tail], context, _)
       when tag in [:if, :elsif] do
    if Expression.eval(expression, context) do
      Liquex.render(contents, context)
    else
      do_render(tail, context)
    end
  end

  defp do_render([{:unless, [expression: expression, contents: contents]} | tail], context, _) do
    if Expression.eval(expression, context) do
      do_render(tail, context)
    else
      Liquex.render(contents, context)
    end
  end

  defp do_render([{:else, [contents: contents]} | _tail], context, _),
    do: Liquex.render(contents, context)

  defp do_render([{:case, argument} | tail], context, _) do
    match = Argument.eval(argument, context)
    do_render(tail, context, match)
  end

  defp do_render([], context, _), do: {[], context}

  defp do_render([{:when, [expression: expressions, contents: contents]} | tail], context, match) do
    result = Enum.any?(expressions, &(match == Argument.eval(&1, context)))

    if result do
      Liquex.render(contents, context)
    else
      do_render(tail, context, match)
    end
  end
end
