defmodule LiquexError do
  defexception [:message]

  @type t :: %__MODULE__{message: String.t()}
end
