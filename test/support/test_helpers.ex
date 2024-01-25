defmodule Liquex.TestHelpers do
  @moduledoc false

  import ExUnit.Assertions

  def assert_parse(doc, match),
    do: assert({:ok, ^match, "", _, _, _} = Liquex.Parser.Base.parse(doc))

  def assert_parse_error(doc), do: assert({:error, _, _, _, _, _} = Liquex.Parser.Base.parse(doc))

  def assert_match_liquid(path, opts \\ []) do
    {:ok, archive} = Hrx.load(path)

    debug = Keyword.get(opts, :debug, false)

    object_json = get_file_contents(archive, ".json") || "{}"
    liquid = get_file_contents(archive, ".liquid")

    context = Jason.decode!(object_json)

    with {liquid_result, 0} <- liquid_render(liquid, object_json),
         {:ok, ast} <- Liquex.parse(liquid),
         {data, _} <- Liquex.render!(ast, context) do
      unless liquid_result == to_string(data) do
        output_diff(liquid_result, to_string(data))

        assert liquid_result == to_string(data)
      else
        if debug do
          IO.puts("Liquid Gem Output:")
          IO.puts(liquid_result)

          IO.puts("\n\nLiquex Output:")
          IO.puts(to_string(data))
        end
      end
    else
      {:error, msg, _} ->
        flunk("Unable to parse: #{msg} in file #{path}")

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

  def render(doc, context \\ Liquex.Context.new(%{})) do
    with {:ok, parsed_doc, _, _, _, _} <- Liquex.Parser.Base.parse(doc),
         {result, _} = Liquex.render!(parsed_doc, context) do
      to_string(result) |> String.trim()
    end
  end

  defp output_diff(left, right) do
    IO.puts("\nOutput does not match. Left is Liquid. Right is Liquex\n")

    Enum.zip(String.split(left, "\n"), String.split(right, "\n"))
    |> Enum.with_index()
    |> Enum.each(fn {{l, r}, i} ->
      if l != r, do: IO.puts("#{i}: \"#{l}\" => \"#{r}\"")
    end)
  end
end
