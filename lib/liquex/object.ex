defmodule Liquex.Object do
  alias Liquex.Argument
  alias Liquex.Filter

  def render([argument, filters: filters], context) do
    argument
    |> Argument.eval(context)
    |> process_filters(filters, context)
    |> to_string()
  end

  defp process_filters(value, filters, context) do
    filters
    |> Enum.reduce(value, &Filter.apply(&2, &1, context))
  end
end
