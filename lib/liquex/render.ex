defmodule Liquex.Render do
  @moduledoc false

  alias Liquex.Context

  @callback render({atom, any}, Context.t()) :: {iodata, Context.t()} | iodata | false

  @type result_t ::
          {iodata(), Context.t()}
          | {:break, iodata(), Context.t()}
          | {:continue, iodata(), Context.t()}

  @spec render(iodata(), Liquex.document_t(), Context.t()) :: result_t

  @doc """
  Renders a Liquid AST `document` into an `iodata`

  A `context` is given to handle temporary contextual information for
  this render.
  """
  def render(content, [], context),
    do: {content |> Enum.reverse(), context}

  def render(content, [tag | tail], %Context{} = context) do
    case do_render(tag, context) do
      # No tag renderer found
      nil ->
        raise Liquex.Error, "No tag renderer found for tag #{tag}"

      {:break, result, context} ->
        {:break, [result | content], context}

      {:continue, result, context} ->
        {:continue, [result | content], context}

      # Returned the rendered results and new context
      {result, %Context{} = context} ->
        render([result | content], tail, context)
    end
  end

  def render(document, %Context{} = context), do: render([], document, context)

  defp do_render({:text, text}, context), do: {text, context}

  defp do_render({{:tag, module}, contents}, context) when is_atom(module),
    do: module.render(contents, context)

  @spec apply_filters(any, [Liquex.Filter.filter_t()], Context.t()) :: {any, Context.t()}
  def apply_filters(value, filters, %Context{} = context),
    do: Enum.reduce(filters, {value, context}, &apply_filter/2)

  defp apply_filter(filter, {value, %Context{filter_module: filter_module} = context}) do
    {filter_module.apply(value, filter, context), context}
  rescue
    # If we have no matching filter, add to errors and return the original value
    UndefinedFunctionError ->
      {value,
       Context.push_error(context, %Liquex.Error{
         message: "Invalid filter #{Liquex.Filter.filter_name(filter)}"
       })}
  end
end
