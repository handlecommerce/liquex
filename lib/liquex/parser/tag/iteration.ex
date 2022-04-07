defmodule Liquex.Parser.Tag.Iteration do
  @moduledoc false

  import NimbleParsec

  alias Liquex.Parser.Argument
  alias Liquex.Parser.Field
  alias Liquex.Parser.Literal
  alias Liquex.Parser.Tag

  def tablerow_tag(combinator \\ empty()) do
    tablerow_parameters = repeat(choice([cols(), limit(), offset()]))

    combinator
    |> ignore(Tag.open_tag())
    |> ignore(string("tablerow"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> unwrap_and_tag(Field.identifier(), :identifier)
    |> ignore(Literal.whitespace(empty(), 1))
    |> ignore(string("in"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> tag(collection(), :collection)
    |> ignore(Literal.whitespace())
    |> tag(tablerow_parameters, :parameters)
    |> ignore(Tag.close_tag())
    |> tag(parsec(:document), :contents)
    |> ignore(Tag.tag_directive("endtablerow"))
    |> tag(:tablerow)
  end

  defp collection do
    choice([Literal.range(), Argument.argument()])
  end

  defp cols do
    ignore(string("cols:"))
    |> unwrap_and_tag(integer(min: 1), :cols)
    |> ignore(Literal.whitespace())
  end

  defp limit do
    ignore(string("limit:"))
    |> unwrap_and_tag(integer(min: 1), :limit)
    |> ignore(Literal.whitespace())
  end

  defp offset do
    ignore(string("offset:"))
    |> unwrap_and_tag(integer(min: 1), :offset)
    |> ignore(Literal.whitespace())
  end
end
