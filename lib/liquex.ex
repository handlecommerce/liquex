defmodule Liquex do
  @moduledoc """
  Documentation for `Liquex`.
  """

  alias Liquex.ControlFlow
  alias Liquex.Object

  def parse(template) do
    case Liquex.Parser.parse(template) do
      {:ok, content, _, _, _, _} -> {:ok, content}
      {:error, reason, _, _, line, _} -> {:error, reason, line}
    end
  end

  def render(document, context \\ %{}) do
    do_render([], document, context)
  end

  defp do_render(content, [], context),
    do: {content |> Enum.reverse(), context}

  defp do_render(content, [{:text, text} | tail], context) do
    [text | content]
    |> do_render(tail, context)
  end

  defp do_render(content, [{:object, object} | tail], context) do
    result = Object.render(object, context)

    [result | content]
    |> do_render(tail, context)
  end

  defp do_render(content, [{:control_flow, tag} | tail], context) do
    {result, context} = ControlFlow.render(tag, context)

    [result | content]
    |> do_render(tail, context)
  end
end
