defmodule Liquex.Render do
  @moduledoc false

  alias Liquex.Context

  @callback render({atom, any}, Context.t()) :: {iodata, Context.t()} | iodata | false

  @spec render(iodata(), Liquex.document_t(), Context.t()) :: {iodata(), Context.t()}
  @doc """
  Renders a Liquid AST `document` into an `iodata`

  A `context` is given to handle temporary contextual information for
  this render.
  """
  def render(content, [], context),
    do: {content |> Enum.reverse(), context}

  def render(content, [tag | tail], %{render_module: custom_module} = context) do
    if !is_nil(custom_module) do
      IO.warn("Use of render with render_module is deprecated.  Use custom tags instead.")
    end

    [
      custom_module,
      Liquex.Render.Tag,
      Liquex.Render.Text,
      Liquex.Render.Object,
      Liquex.Render.ControlFlow,
      Liquex.Render.Variable,
      Liquex.Render.Iteration
    ]
    |> do_render(tag, context)
    |> case do
      # No tag renderer found
      nil ->
        raise Liquex.Error, "No tag renderer found for tag #{tag}"

      # Returned the rendered results and new context
      {result, %Context{} = context} ->
        render([result | content], tail, context)

      # Returned the rendered results without a new context
      result ->
        render([result | content], tail, context)
    end
  end

  defp do_render(modules, tag, context) do
    modules
    |> Enum.reject(&is_nil/1)
    |> Enum.find_value(& &1.render(tag, context))
  end
end
