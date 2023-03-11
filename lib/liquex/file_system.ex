defprotocol Liquex.FileSystem do
  @moduledoc """
  Behaviour for file system access used by the `render` tag.
  """

  @spec read_template_file(term, String.t()) :: String.t() | no_return()
  @doc "Read a template from the filesystem"
  def read_template_file(file_system, template_path)
end

defmodule Liquex.BlankFileSystem do
  @moduledoc """
  Default file system that throws an error when trying to call render within a
  template.
  """

  defstruct []
end

defimpl Liquex.FileSystem, for: Liquex.BlankFileSystem do
  def read_template_file(_file_system, _template_path),
    do: raise(Liquex.Error, message: "This liquid context does not allow includes.")
end

defmodule Liquex.LocalFileSystem do
  @moduledoc """
  This implements an abstract file system which retrieves template files named
  in a manner similar to liquid, ie. with the template name prefixed with an
  underscore. The extension ".liquid" is also added.

  For security reasons, template paths are only allowed to contain letters,
  numbers, and underscore.

  Example:

    iex> file_system = Liquex.LocalFileSystem.new("/some/path")
    iex> Liquex.LocalFileSystem.full_path(file_system, "mypartial")
    "/some/path/_mypartial.liquid"

  Optionally in the second argument you can specify a custom pattern for template filenames.
  %s is replaced with the template name. Default pattern is "_%s.liquid".

  Example:

    iex> file_system = Liquex.LocalFileSystem.new("/some/path", "%s.html")
    iex> Liquex.LocalFileSystem.full_path(file_system, "mypartial")
    "/some/path/mypartial.html"
  """
  defstruct [:root_path, :pattern]

  @type t :: %__MODULE__{
          root_path: String.t(),
          pattern: String.t()
        }

  @spec new(String.t(), String.t()) :: t()
  def new(root_path, pattern \\ "_%s.liquid") do
    %__MODULE__{
      root_path: root_path,
      pattern: pattern
    }
  end

  @spec full_path(t(), String.t()) :: String.t()
  def full_path(%__MODULE__{root_path: root_path, pattern: pattern}, template_path) do
    # Force check that template path is legal
    unless Regex.match?(~r{\A[^./][a-zA-Z0-9_/]+\z}, template_path) do
      raise Liquex.Error, message: "Illegal template path '#{template_path}'"
    end

    # Replace the template name with the pattern
    template_name = String.replace(pattern, "%s", Path.basename(template_path))

    root_path
    |> Path.join(path(template_path))
    |> Path.join(template_name)
    |> Path.expand()
  end

  @spec path(String.t()) :: String.t()
  defp path(template_path) do
    case Path.dirname(template_path) do
      "." -> ""
      path -> path
    end
  end
end

defimpl Liquex.FileSystem, for: Liquex.LocalFileSystem do
  def read_template_file(%Liquex.LocalFileSystem{} = file_system, template_path) do
    file_system
    |> Liquex.LocalFileSystem.full_path(template_path)
    |> File.read()
    |> case do
      {:ok, contents} -> contents
      _ -> raise Liquex.Error, message: "No such template '#{template_path}'"
    end
  end
end
