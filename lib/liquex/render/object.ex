defmodule Liquex.Render.Object do
  @moduledoc """
  Renders out Liquid objects
  """

  alias Liquex.Argument

  def render([argument, filters: filters], context) do
    [argument]
    |> Argument.eval(context)
    |> process_filters(filters, context)
    |> to_string()
  end

  defp process_filters(value, filters, context) do
    filters
    |> Enum.reduce(value, &context.filter.apply(&2, &1, context))
  end
end
