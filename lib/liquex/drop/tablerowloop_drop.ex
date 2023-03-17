defmodule Liquex.Drop.TablerowloopDrop do
  defstruct [:length, :row, :col, :cols, :index]

  @behaviour Liquex.Drop

  @type t :: %__MODULE__{
          length: non_neg_integer,
          col: non_neg_integer(),
          row: non_neg_integer(),
          cols: non_neg_integer(),
          index: non_neg_integer()
        }

  def new(length, cols, index) do
    %__MODULE__{
      length: length,
      col: rem(index, cols),
      row: div(index, cols),
      cols: cols,
      index: index
    }
  end

  @spec col(t) :: pos_integer()
  def col(%__MODULE__{col: col}), do: col + 1

  @spec col0(t) :: non_neg_integer()
  def col0(%__MODULE__{col: col}), do: col

  def col_first(%__MODULE__{col: col}), do: col == 0
  def col_last(%__MODULE__{col: col, cols: cols}), do: col == cols - 1

  def first(%__MODULE__{index: index}), do: index == 0

  def index(%__MODULE__{index: index}), do: index + 1
  def index0(%__MODULE__{index: index}), do: index

  def last(%__MODULE__{index: index, length: length}), do: index == length - 1

  def length(%__MODULE__{length: length}), do: length

  def rindex(%__MODULE__{length: length, index: index}), do: length - index
  def rindex0(%__MODULE__{length: length, index: index}), do: length - index - 1

  def row(%__MODULE__{row: row}), do: row + 1
end
