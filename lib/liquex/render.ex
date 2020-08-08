defmodule Liquex.Render do
  @moduledoc false

  alias Liquex.Context

  @callback render({atom, any}, Context.t()) :: {any, Context.t()} | false

  @spec render(iolist(), Liquex.document_t(), Context.t()) :: {iolist(), Context.t()}
  @doc """
  Renders a Liquid AST `document` into an `iolist`

  A `context` is given to handle temporary contextual information for
  this render.
  """
  def render(content, [], context),
    do: {content |> Enum.reverse(), context}

  def render(content, [tag | tail], %{render_module: custom_module} = context) do
    [
      custom_module,
      Liquex.Render.Text,
      Liquex.Render.Object,
      Liquex.Render.ControlFlow,
      Liquex.Render.Variable,
      Liquex.Render.Iteration
    ]
    |> do_render(tag, context)
    |> case do
      {result, context} ->
        [result | content]
        |> render(tail, context)

      _ ->
        raise LiquexError, "No tag renderer found for tag #{tag}"
    end
  end

  defp do_render(modules, tag, context) do
    modules
    |> Enum.reject(&is_nil/1)
    |> Enum.find_value(& &1.render(tag, context))
  end
end
