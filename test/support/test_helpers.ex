defmodule Liquex.TestHelpers do
  @moduledoc false

  import ExUnit.Assertions

  def assert_parse(doc, match), do: assert({:ok, ^match, "", _, _, _} = Liquex.Parser.parse(doc))

  def assert_match_liquid(liquid_path) do
    object_json = File.read!(String.replace_suffix(liquid_path, ".liquid", ".json"))
    object = Jason.decode!(object_json)

    context = Liquex.Context.new(object)

    with liquid <- File.read!(liquid_path),
         {:ok, ast} <- Liquex.parse(liquid),
         {data, _} <- Liquex.render(ast, context),
         {liquid_result, 0} <- liquid_render(liquid, object_json) do
      assert String.trim_trailing(liquid_result) == to_string(data)
    else
      {:error, msg, _} -> flunk("Unable to parse: #{msg}")
      _r -> flunk("Could not parse")
    end
  end

  def liquid_render(liquid, json),
    do: System.cmd("ruby", ["test/render.rb", liquid, json])
end
