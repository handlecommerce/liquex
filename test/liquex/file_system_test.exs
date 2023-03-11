defmodule Liquex.FileSystemTest do
  @moduledoc false

  use ExUnit.Case, async: true

  doctest Liquex.LocalFileSystem

  alias Liquex.BlankFileSystem

  describe "BlankFileSystem" do
    test "read_template_file throws an error" do
      fs = %BlankFileSystem{}
      assert_raise(Liquex.Error, fn -> Liquex.FileSystem.read_template_file(fs, "test") end)
    end
  end
end
