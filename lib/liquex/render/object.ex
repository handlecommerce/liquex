defmodule Liquex.Render.Object do
  @moduledoc false

  alias Liquex.Argument
  alias Liquex.Context

  @spec render(any, Context.t()) :: String.t()
  def render([argument, filters: filters], %Context{} = context) do
    argument
    |> List.wrap()
    |> Argument.eval(context)
    |> process_filters(filters, context)
    |> to_string()
  end

  @spec process_filters(any, [any], Context.t()) :: any
  defp process_filters(value, filters, %Context{filter_module: filter_module} = context) do
    filters
    |> Enum.reduce(value, fn filter, memo ->
      memo
      |> filter_module.apply(filter, context)
    end)
  end
end
