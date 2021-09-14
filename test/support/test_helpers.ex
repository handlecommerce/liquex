defmodule Liquex.TestHelpers do
  @moduledoc false

  import ExUnit.Assertions

  def assert_parse(doc, match), do: assert({:ok, ^match, "", _, _, _} = Liquex.Parser.parse(doc))

  def assert_match_liquid(path) do
    {:ok, archive} = Hrx.load(path)

    object_json = get_file_contents(archive, ".json")
    liquid = get_file_contents(archive, ".liquid")

    context =
      object_json
      |> Jason.decode!()
      |> Liquex.Context.new()

    with {:ok, ast} <- Liquex.parse(liquid),
         {data, _} <- Liquex.render(ast, context),
         {liquid_result, 0} <- liquid_render(liquid, object_json) do
      assert String.trim_trailing(liquid_result) == to_string(data)
    else
      {:error, msg, _} ->
        flunk("Unable to parse: #{msg}")

      _r ->
        IO.puts("Could not execute liquid for ruby.  Ignoring...")
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
