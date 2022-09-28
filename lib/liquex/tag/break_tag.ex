defmodule Liquex.Tag.BreakTag do
  @moduledoc """
  Causes the loop to stop iterating when it encounters the break tag.

  ### Input

      {% for i in (1..5) %}
        {% if i == 4 %}
          {% break %}
        {% else %}
          {{ i }}
        {% endif %}
      {% endfor %}

  ### Output

      1 2 3
  """

  @behaviour Liquex.Tag

  alias Liquex.Parser.Tag

  import NimbleParsec

  @impl true
  def parse do
    ignore(Tag.tag_directive("break"))
  end

  @impl true
  def parse_liquid_tag do
    ignore(Tag.liquid_tag_directive("break"))
  end

  @impl true
  def render(_, context) do
    {:break, [], context}
  end
end
