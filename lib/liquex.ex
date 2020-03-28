defmodule Liquex do
  @moduledoc """
  Documentation for `Liquex`.
  """

  alias Liquex.Context

  alias Liquex.Render.{
    ControlFlow,
    Iteration,
    Object,
    Variable
  }

  @type document_t :: [
          {:control_flow, nonempty_maybe_improper_list}
          | {:iteration, [...]}
          | {:object, [...]}
          | {:text, any}
          | {:variable, [...]}
        ]

  @spec parse(String.t(), module) :: {:ok, document_t} | {:error, String.t(), pos_integer()}
  def parse(template, parser \\ Liquex.Parser) do
    case parser.parse(template) do
      {:ok, content, _, _, _, _} -> {:ok, content}
      {:error, reason, _, _, line, _} -> {:error, reason, line}
    end
  end

  @spec render(document_t(), Context.t()) :: {iolist(), Context.t()}
  def render(document, context \\ %Context{}),
    do: do_render([], document, context)

  @spec do_render(iolist(), document_t(), Context.t()) :: {iolist(), Context.t()}
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

  defp do_render(content, [{:variable, tag} | tail], context) do
    {result, context} = Variable.render(tag, context)

    [result | content]
    |> do_render(tail, context)
  end

  defp do_render(content, [{:iteration, tag} | tail], context) do
    {result, context} = Iteration.render(tag, context)

    [result | content]
    |> do_render(tail, context)
  end
end
