defmodule Liquex.Render.Filter do
  @moduledoc false
  alias Liquex.Context

  @spec apply_filters(any, [Liquex.Filter.filter_t()], Context.t()) :: {any, Context.t()}
  def apply_filters(value, filters, %Context{} = context),
    do: Enum.reduce(filters, {value, context}, &apply_filter/2)

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
