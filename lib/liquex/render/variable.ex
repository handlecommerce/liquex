defmodule Liquex.Render.Variable do
  @moduledoc """
  Renders out a variable tag
  """

  alias Liquex.Argument
  alias Liquex.Context

  @spec render(any, Context.t()) :: {iolist(), Context.t()}
  def render([assign: [left: left, right: right]], %Context{} = context) when is_binary(left) do
    right = Argument.eval(right, context)

    context = Context.assign(context, left, right)

    {[], context}
  end

  def render(
        [capture: [identifier: identifier, contents: contents]],
        %Context{} = context
      ) do
    {rendered_contents, context} = Liquex.render(contents, context)
    {[], Context.assign(context, identifier, rendered_contents)}
  end

  def render(
        [increment: [identifier: identifier, by: increment]],
        %Context{variables: variables} = context
      ) do
    value = Map.get(variables, identifier, 0) + increment
    {[], Context.assign(context, identifier, value)}
  end
end
