defmodule Liquex.Filter do
  alias Liquex.Argument

  @spec apply(any, {:filter, [...]}, map) :: any
  def apply(value, {:filter, [function, {:arguments, arguments}]}, context) do
    function_args =
      Enum.map(
        arguments,
        &Argument.eval(&1, context)
      ) ++ [context]

    Kernel.apply(__MODULE__, String.to_existing_atom(function), [value | function_args])
  end

  @doc """
  Returns the absolute value of a number.

  iex> Liquex.Filter.abs(-1, %{})
  1
  iex> Liquex.Filter.abs(1, %{})
  1
  iex> Liquex.Filter.abs("-1.1", %{})
  1.1
  """
  @spec abs(String.t() | number, any) :: number
  def abs(value, _) when is_binary(value) do
    {float, ""} = Float.parse(value)
    abs(float)
  end

  def abs(value, _), do: abs(value)

  @doc """
  Appends text to the end of the value

  iex> Liquex.Filter.append("myfile", ".html", %{})
  "myfile.html"
  """
  @spec append(String.t(), String.t(), map()) :: String.t()
  def append(value, text, _), do: value <> text

  @doc """
  Sets a minimum value

  iex> Liquex.Filter.at_least(3, 5, %{})
  5

  iex> Liquex.Filter.at_least(5, 3, %{})
  5
  """
  @spec at_least(number, number, map()) :: number
  def at_least(value, min, _) when value > min, do: value
  def at_least(_value, min, _), do: min

  @doc """
  Sets a maximum value

  iex> Liquex.Filter.at_most(4, 5, %{})
  4

  iex> Liquex.Filter.at_most(4, 3, %{})
  3
  """
  @spec at_most(number, number, map()) :: number
  def at_most(value, max, _) when value < max, do: value
  def at_most(_value, max, _), do: max

  @doc """
  Capitalizes a string

  iex> Liquex.Filter.capitalize("title", %{})
  "Title"

  iex> Liquex.Filter.capitalize("my great title", %{})
  "My great title"
  """
  @spec capitalize(String.t(), map()) :: String.t()
  def capitalize(value, _), do: String.capitalize(value)

  @doc """
  Rounds the input up to the nearest whole number. Liquid tries to convert the input to a number before the filter is applied.

  iex> Liquex.Filter.ceil(1.2, %{})
  2

  iex> Liquex.Filter.ceil(2.0, %{})
  2

  iex> Liquex.Filter.ceil(183.357, %{})
  184

  iex> Liquex.Filter.ceil("3.5", %{})
  4
  """
  @spec ceil(number | String.t(), map()) :: number
  def ceil(value, _) when is_binary(value) do
    {num, ""} = Float.parse(value)
    Float.ceil(num) |> trunc()
  end

  def ceil(value, _), do: Float.ceil(value) |> trunc()

  @doc """
  Removes any nil values from an array.

  iex> Liquex.Filter.compact([1, 2, nil, 3], %{})
  [1,2,3]

  iex> Liquex.Filter.compact([1, 2, 3], %{})
  [1,2,3]
  """
  @spec compact([any], map()) :: [any]
  def compact(value, _) when is_list(value),
    do: Enum.reject(value, &is_nil/1)

  @doc """
  Concatenates (joins together) multiple arrays. The resulting array contains all the items

  iex> Liquex.Filter.concat([1,2], [3,4], %{})
  [1,2,3,4]
  """
  def concat(value, other, _) when is_list(value) and is_list(other),
    do: value ++ other

  @doc """
  Converts a timestamp into another date format.

  The format for this syntax is the same as strftime. The input uses the same format as Ruby’s Time.parse.

  iex> Liquex.Filter.date(~D[2000-01-01], "%m/%d/%Y", %{})
  "01/01/2000"

  iex> Liquex.Filter.date("2000-01-01", "%m/%d/%Y", %{})
  "01/01/2000"

  iex> Liquex.Filter.date("January 1, 2000", "%m/%d/%Y", %{})
  "01/01/2000"

  iex> Liquex.Filter.date("1/2/2000", "%m/%d/%Y", %{})
  "01/02/2000"

  iex> Liquex.Filter.date("March 14, 2016", "%b %d, %y", %{})
  "Mar 14, 16"
  """
  def date(%Date{} = value, format, _), do: Timex.format!(value, format, :strftime)
  def date(%DateTime{} = value, format, _), do: Timex.format!(value, format, :strftime)
  def date(%NaiveDateTime{} = value, format, _), do: Timex.format!(value, format, :strftime)

  def date("now", format, context), do: date(Timex.now(), format, context)
  def date("today", format, context), do: date(Timex.today(), format, context)

  def date(value, format, context) when is_binary(value) do
    # Thanks to the nonspecific definition of the format in the spec, we parse
    # some common date formats
    results =
      with {:error, _} <- Timex.parse(value, "%F %T"),
           {:error, _} <- Timex.parse(value, "{YYYY}-{0M}-{D}"),
           {:error, _} <- Timex.parse(value, "%-m/%-d/%Y", :strftime),
           {:error, _} = r <- Timex.parse(value, "%B %e, %Y", :strftime) do
        r
      end

    case results do
      {:ok, parsed_date} ->
        parsed_date
        |> NaiveDateTime.to_date()
        |> date(format, context)

      _ ->
        nil
    end
  end

  @doc """
  Allows you to specify a fallback in case a value doesn’t exist. default will show its value
  if the left side is nil, false, or empty.

  iex> Liquex.Filter.default("1.99", "2.99", %{})
  "1.99"

  iex> Liquex.Filter.default("", "2.99", %{})
  "2.99"
  """
  def default(value, def_value, _) when value in [nil, "", false, []], do: def_value
  def default(value, _, _), do: value

  @doc """
  Divides a number by another number.

  The result is rounded down to the nearest integer (that is, the floor) if the divisor is an integer.

  iex> Liquex.Filter.divided_by(16, 4, %{})
  4

  iex> Liquex.Filter.divided_by(5, 3, %{})
  1

  iex> Liquex.Filter.divided_by(20, 7.0, %{})
  2.857142857142857
  """
  def divided_by(value, divisor, _) when is_integer(divisor), do: trunc(value / divisor)
  def divided_by(value, divisor, _), do: value / divisor

  @doc """
  Makes each character in a string lowercase. It has no effect on strings which are already all lowercase.

  iex> Liquex.Filter.downcase("Parker Moore", %{})
  "parker moore"

  iex> Liquex.Filter.downcase("apple", %{})
  "apple"
  """
  def downcase(nil, _), do: nil
  def downcase(value, _), do: String.downcase(value)
end
