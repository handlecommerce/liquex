defmodule Liquex.Render do
  alias Liquex.Context

  @spec render(iolist(), Liquex.document_t(), Context.t()) :: {iolist(), Context.t()}
  @doc """
  Renders a Liquid AST `document` into an `iolist`

  A `context` is given to handle temporary contextual information for
  this render.
  """
  def render(content, [], context),
    do: {content |> Enum.reverse(), context}

  def render(content, [tag | tail], %{render_modules: custom_modules} = context) do
    [
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
        custom_modules
        |> do_render(tag, context)
        |> case do
          {result, context} ->
            [result | content]
            |> render(tail, context)

          _ ->
            raise "No tag renderer found"
        end
    end
  end

  defp do_render(modules, tag, context) do
    modules
    |> Enum.find_value(& &1.render(tag, context))
  end
end
