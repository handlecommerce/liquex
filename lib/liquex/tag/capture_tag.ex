defmodule Liquex.Tag.CaptureTag do
  @moduledoc """
  Captures the string inside of the opening and closing tags and assigns it to a
  variable. Variables created using capture are stored as strings.

  ### Input

      {% capture my_variable %}I am being captured.{% endcapture %}
      {{ my_variable }}

  ### Output

      I am being captured.

  Using capture, you can create complex strings using other variables created
  with assign.

  ### Input
      {% assign favorite_food = "pizza" %}
      {% assign age = 35 %}

      {% capture about_me %}
      I am {{ age }} and my favorite food is {{ favorite_food }}.
      {% endcapture %}

      {{ about_me }}

  ### Output
      I am 35 and my favourite food is pizza.
  """
  false

  @behaviour Liquex.Tag

  alias Liquex.Context
  alias Liquex.Parser.Field
  alias Liquex.Parser.Literal
  alias Liquex.Parser.Tag

  import NimbleParsec

  def parse do
    ignore(Tag.open_tag())
    |> ignore(string("capture"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> unwrap_and_tag(Field.identifier(), :identifier)
    |> ignore(Tag.close_tag())
    |> tag(parsec(:document), :contents)
    |> ignore(Tag.tag_directive("endcapture"))
  end

  def render([identifier: identifier, contents: contents], %Context{} = context) do
    {rendered_contents, context} = Liquex.render!(contents, context)
    {[], Context.assign(context, identifier, to_string(rendered_contents))}
  end
end
