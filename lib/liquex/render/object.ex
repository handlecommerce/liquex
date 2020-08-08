defmodule Liquex.Render.Object do
  @moduledoc false

  alias Liquex.Argument
  alias Liquex.Context

  @behaviour Liquex.Render

  @impl Liquex.Render
  @spec render(any, Context.t()) :: {String.t(), Context.t()}
  def render({:object, tag}, context), do: do_render(tag, context)

  def render(_, _), do: false

  def do_render([argument, filters: filters], %Context{} = context) do
    argument
    |> List.wrap()
    |> Argument.eval(context)
    |> process_filters(filters, context)
  end

  @spec process_filters(any, [Liquex.Filter.filter_t()], Context.t()) :: {any, Context.t()}
  defp process_filters(value, filters, %Context{} = context) do
    {result, context} =
      filters
      |> Enum.reduce({value, context}, &apply_filter/2)

    {to_string(result), context}
  end

  defp apply_filter(filter, {value, %Context{filter_module: filter_module} = context}) do
    {filter_module.apply(value, filter, context), context}
  rescue
    # If we have no matching filter, add to errors and return the original value
    UndefinedFunctionError ->
      {value,
       Context.push_error(context, %LiquexError{
         message: "Invalid filter #{Liquex.Filter.filter_name(filter)}"
       })}
  end
end
