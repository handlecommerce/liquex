defmodule Liquex.MockFileSystem do
  defstruct [:values]

  def new(values), do: %__MODULE__{values: values}
end

defimpl Liquex.FileSystem, for: Liquex.MockFileSystem do
  def read_template_file(%{values: values}, template_path) when is_map(values),
    do: Map.get(values, template_path)
end
