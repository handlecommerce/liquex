defmodule Liquex.Tag.ContinueTag do
  @moduledoc """
  Causes the loop to skip the current iteration when it encounters the continue
  tag.

  ### Input

      {% for i in (1..5) %}
        {% if i == 4 %}
          {% continue %}
        {% else %}
          {{ i }}
        {% endif %}
      {% endfor %}

  ### Output

      1 2 3   5
  """

  @behaviour Liquex.Tag

  alias Liquex.Parser.Tag

  import NimbleParsec

  @impl true
  def parse, do: ignore(Tag.tag_directive("continue"))

  @impl true
  def parse_liquid_tag, do: ignore(Tag.liquid_tag_directive("continue"))

  @impl true
  def render(_, context), do: {:continue, [], context}
end
