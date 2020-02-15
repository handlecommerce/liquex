defmodule Liquex.Variable do
  alias Liquex.Argument

  def render([assign: [left: left, right: right]], context) do
    {[], Map.put(context, left, Argument.eval(right, context))}
  end

  def render([capture: [identifier: identifier, contents: contents]], context) do
    {rendered_contents, context} = Liquex.render(contents, context)
    {[], Map.put(context, identifier, rendered_contents)}
  end

  def render([increment: [identifier: identifier, by: increment]], context) do
    value = Map.get(context, identifier, 0) + increment
    {[], Map.put(context, identifier, value)}
  end
end
