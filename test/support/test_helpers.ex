defmodule Liquex.TestHelpers do
  @moduledoc false

  import ExUnit.Assertions

  def assert_parse(doc, match),
    do: assert({:ok, ^match, "", _, _, _} = Liquex.Parser.Base.parse(doc))

  def assert_match_liquid(path) do
    {:ok, archive} = Hrx.load(path)

    object_json = get_file_contents(archive, ".json") || "{}"
    liquid = get_file_contents(archive, ".liquid")

    context = Jason.decode!(object_json)

    with {liquid_result, 0} <- liquid_render(liquid, object_json),
         {:ok, ast} <- Liquex.parse(liquid),
         {data, _} <- Liquex.render(ast, context) do
      assert liquid_result == to_string(data)
    else
      {:error, msg, _} ->
        flunk("Unable to parse: #{msg}")

      {response, exit_code} when is_integer(exit_code) ->
        flunk("Unable to parse: '#{response}', exit code: #{exit_code}")

      _r ->
        IO.warn("Could not execute liquid for ruby.  Ignoring...")
        :ok
    end
  end

  defp get_file_contents(%Hrx.Archive{entries: entries}, extension) do
    entries
    |> Enum.filter(&(Path.extname(elem(&1, 0)) == extension))
    |> Enum.map(&elem(&1, 1))
    |> case do
      [%Hrx.Entry{contents: {:file, contents}}] -> contents
      _ -> nil
    end
  end

  def liquid_render(liquid, json),
    do: System.cmd("ruby", ["test/render.rb", liquid, json])
end
