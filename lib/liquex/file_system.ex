defmodule Liquex.FileSystem do
  @doc "Read a template from the filesystem"
  @callback read_template_file(struct(), String.t()) :: String.t() | no_return()
end

defmodule Liquex.BlankFileSystem do
  @moduledoc """
  Default file system that throws an error when trying to call render within a
  template.
  """
  @behaviour Liquex.FileSystem

  defstruct []

  def read_template_file(_file_system, _template_path),
    do: raise(File.Error, reason: "This liquid context does not allow includes.")
end
