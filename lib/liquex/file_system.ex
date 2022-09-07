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
    do: raise(File.Error, reason: "This liquid context does not allow includes.")
end
