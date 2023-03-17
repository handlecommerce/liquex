defmodule Liquex.Drop do
  @doc "Catch all for the method"
  @callback liquid_method_missing(String.t()) :: any

  @optional_callbacks liquid_method_missing: 1
end
