defmodule Liquex.Render.Object do
  @moduledoc false

  alias Liquex.Argument
  alias Liquex.Context
  alias Liquex.Render.Filter

  @behaviour Liquex.Render

  @impl Liquex.Render
  @spec render(any, Context.t()) :: {String.t(), Context.t()}
  def render({:object, tag}, context), do: do_render(tag, context)

  def render(_, _), do: false

  def do_render([argument, filters: filters], %Context{} = context) do
    {result, context} =
      argument
      |> List.wrap()
      |> Argument.eval(context)
      |> Filter.apply_filters(filters, context)

    {to_string(result), context}
  end
end
