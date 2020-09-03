defmodule Liquex.Render.Variable do
  @moduledoc false

  alias Liquex.Argument
  alias Liquex.Context
  alias Liquex.Render.Filter

  @behaviour Liquex.Render

  @impl Liquex.Render
  @spec render(any, Context.t()) :: {iolist, Context.t()}
  def render({:variable, tag}, context), do: do_render(tag, context)
  def render(_, _), do: false

  @spec do_render(any, Context.t()) :: {iolist(), Context.t()}
  defp do_render(
         [assign: [left: left, right: [right, {:filters, filters}]]],
         %Context{} = context
       )
       when is_binary(left) do
    {right, context} =
      right
      |> Argument.eval(context)
      |> Filter.apply_filters(filters, context)

    context = Context.assign(context, left, right)

    {[], context}
  end

  defp do_render(
         [capture: [identifier: identifier, contents: contents]],
         %Context{} = context
       ) do
    {rendered_contents, context} = Liquex.render(contents, context)
    {[], Context.assign(context, identifier, rendered_contents)}
  end

  defp do_render(
         [increment: [identifier: identifier, by: increment]],
         %Context{variables: variables} = context
       ) do
    value = Map.get(variables, identifier, 0) + increment
    {[], Context.assign(context, identifier, value)}
  end
end
