defmodule Liquex.Drop.ForloopDrop do
  defstruct [:index, :length]

  @behaviour Liquex.Drop

  @type t :: %__MODULE__{
          index: non_neg_integer,
          length: non_neg_integer
        }

  @spec new(non_neg_integer, non_neg_integer) :: t()
  def new(index, length) do
    %__MODULE__{index: index, length: length}
  end

  @spec index(t()) :: pos_integer
  def index(%__MODULE__{index: index}), do: index + 1

  @spec index0(t()) :: non_neg_integer
  def index0(%__MODULE__{index: index}), do: index

  @spec rindex(t()) :: pos_integer
  def rindex(%__MODULE__{} = drop), do: drop.length - drop.index

  @spec rindex0(t()) :: non_neg_integer
  def rindex0(%__MODULE__{} = drop), do: rindex(drop) - 1

  @spec first(t()) :: boolean
  def first(%__MODULE__{index: index}), do: index == 0

  @spec last(t()) :: boolean
  def last(%__MODULE__{} = drop), do: drop.index == drop.length - 1

  @spec length(t()) :: non_neg_integer()
  def length(%__MODULE__{length: length}), do: length
end
