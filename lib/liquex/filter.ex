defmodule Liquex.Filter do
  @moduledoc """
  Contains all the basic filters for Liquid
  """

  @type filter_t :: {:filter, [...]}
  @callback apply(any, filter_t, map) :: any

  alias Liquex.Context

  defmacro __using__(_) do
    quote do
      @behaviour Liquex.Filter

      @spec apply(any, Liquex.Filter.filter_t(), map) :: any
      @impl Liquex.Filter
      def apply(value, filter, context),
        do: Liquex.Filter.apply(__MODULE__, value, filter, context)
    end
  end

  @spec filter_name(filter_t) :: String.t()
  def filter_name({:filter, [filter_name | _]}), do: filter_name

  def apply(
        mod \\ __MODULE__,
        value,
        {:filter, [function, {:arguments, arguments}]},
        context
      ) do
    func = String.to_existing_atom(function)

    function_args =
      Enum.map(
        arguments,
        &Liquex.Argument.eval(&1, context)
      )
      |> merge_keywords()

    mod =
      if mod != __MODULE__ and Kernel.function_exported?(mod, func, length(function_args) + 2) do
        mod
      else
        __MODULE__
      end

    Kernel.apply(mod, func, [value | function_args] ++ [context])
  rescue
    # credo:disable-for-next-line
    ArgumentError -> raise LiquexError, "Invalid filter #{function}"
  end

  # Merges the tuples at the end of the argument list into a keyword list, but with string keys
  #     value, size, {"crop", direction}, {"filter", filter}
  # becomes
  #     value, size, [{"crop", direction}, {"filter", filter}]
  defp merge_keywords(arguments) do
    {keywords, rest} =
      arguments
      |> Enum.reverse()
      |> Enum.split_while(&is_tuple/1)

    case keywords do
      [] -> rest
      _ -> [Enum.reverse(keywords) | rest]
    end
    |> Enum.reverse()
  end

  @doc """
  Returns the absolute value of `value`.

  ## Examples

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
  Appends `text` to the end of `value`

  ## Examples

      iex> Liquex.Filter.append("myfile", ".html", %{})
      "myfile.html"
  """
  @spec append(String.t(), String.t(), map()) :: String.t()
  def append(value, text, _), do: value <> text

  @doc """
  Sets a minimum value

  ## Examples

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

  ## Examples

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

  ## Examples

      iex> Liquex.Filter.capitalize("title", %{})
      "Title"

      iex> Liquex.Filter.capitalize("my great title", %{})
      "My great title"
  """
  @spec capitalize(String.t(), map()) :: String.t()
  def capitalize(value, _), do: String.capitalize(value)

  @doc """
  Rounds `value` up to the nearest whole number. Liquid tries to convert the input to a number before the filter is applied.

  ## Examples

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

  ## Examples

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

  ## Examples

      iex> Liquex.Filter.concat([1,2], [3,4], %{})
      [1,2,3,4]
  """
  def concat(value, other, _) when is_list(value) and is_list(other),
    do: value ++ other

  @doc """
  Converts `value` timestamp into another date `format`.

  The format for this syntax is the same as strftime. The input uses the same format as Ruby’s Time.parse.

  ## Examples

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

  def date("now", format, context), do: date(DateTime.utc_now(), format, context)
  def date("today", format, context), do: date(Date.utc_today(), format, context)

  def date(value, format, context) when is_binary(value) do
    # Thanks to the nonspecific definition of the format in the spec, we parse
    # some common date formats
    case DateTimeParser.parse_datetime(value, assume_time: true) do
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

  ## Examples

      iex> Liquex.Filter.default("1.99", "2.99", %{})
      "1.99"

      iex> Liquex.Filter.default("", "2.99", %{})
      "2.99"
  """
  def default(value, def_value, _) when value in [nil, "", false, []], do: def_value
  def default(value, _, _), do: value

  @doc """
  Divides a number by another number.

  ## Examples

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
  Makes each character in a string lowercase. It has no effect on strings
  which are already all lowercase.

  ## Examples

      iex> Liquex.Filter.downcase("Parker Moore", %{})
      "parker moore"

      iex> Liquex.Filter.downcase("apple", %{})
      "apple"
  """
  def downcase(nil, _), do: nil
  def downcase(value, _), do: String.downcase(value)

  @doc """
  Escapes a string by replacing characters with escape sequences (so that the string can
  be used in a URL, for example). It doesn’t change strings that don’t have anything to
  escape.

  ## Examples

      iex> Liquex.Filter.escape("Have you read 'James & the Giant Peach'?", %{})
      "Have you read &apos;James &amp; the Giant Peach&apos;?"

      iex> Liquex.Filter.escape("Tetsuro Takara", %{})
      "Tetsuro Takara"
  """
  def escape(value, _),
    do: HtmlEntities.encode(value)

  @doc """
  Escapes a string by replacing characters with escape sequences (so that the string can
  be used in a URL, for example). It doesn’t change strings that don’t have anything to
  escape.

  ## Examples

      iex> Liquex.Filter.escape_once("1 &lt; 2 &amp; 3", %{})
      "1 &lt; 2 &amp; 3"
  """
  def escape_once(value, _),
    do: value |> HtmlEntities.decode() |> HtmlEntities.encode()

  @doc """
  Returns the first item of an array.

  ## Examples

      iex> Liquex.Filter.first([1, 2, 3], %{})
      1

      iex> Liquex.Filter.first([], %{})
      nil
  """
  def first([], _), do: nil
  def first([f | _], _), do: f

  @doc """
  Rounds the input down to the nearest whole number. Liquid tries to convert the input to a
  number before the filter is applied.

  ## Examples

      iex> Liquex.Filter.floor(1.2, %{})
      1

      iex> Liquex.Filter.floor(2.0, %{})
      2
  """
  def floor(value, _), do: Kernel.trunc(value)

  @doc """
  Combines the items in `values` into a single string using `joiner` as a separator.

  ## Examples

      iex> Liquex.Filter.join(~w(John Paul George Ringo), " and ", %{})
      "John and Paul and George and Ringo"
  """
  def join(values, joiner, _), do: Enum.join(values, joiner)

  @doc """
  Returns the last item of `arr`.

  ## Examples

      iex> Liquex.Filter.last([1, 2, 3], %{})
      3

      iex> Liquex.Filter.first([], %{})
      nil
  """
  @spec last(list, Liquex.Context.t()) :: any
  def last(arr, context), do: arr |> Enum.reverse() |> first(context)

  @doc """
  Removes all whitespace (tabs, spaces, and newlines) from the left side of a string.
  It does not affect spaces between words.

  ## Examples

      iex> Liquex.Filter.lstrip("          So much room for activities!          ", %{})
      "So much room for activities!          "
  """
  @spec lstrip(String.t(), Context.t()) :: String.t()
  def lstrip(value, _), do: value |> String.trim_leading()

  @doc """
  Creates an array (`arr`) of values by extracting the values of a named property from another object (`key`).

  ## Examples

      iex> Liquex.Filter.map([%{"a" => 1}, %{"a" => 2, "b" => 1}], "a", %{})
      [1, 2]
  """
  @spec map([any], term, Context.t()) :: [any]
  def map(arr, key, _), do: Enum.map(arr, &Liquex.Indifferent.get(&1, key, nil))

  @doc """
  Subtracts a number from another number.

  ## Examples

      iex> Liquex.Filter.minus(4, 2, %{})
      2

      iex> Liquex.Filter.minus(183.357, 12, %{})
      171.357
  """
  @spec minus(number, number, Context.t()) :: number
  def minus(left, right, _), do: left - right

  @doc """
  Returns the remainder of a division operation.

  ## Examples

      iex> Liquex.Filter.modulo(3, 2, %{})
      1

      iex> Liquex.Filter.modulo(183.357, 12, %{})
      3.357
  """
  @spec modulo(number, number, Context.t()) :: number
  def modulo(left, right, _) when is_float(left) or is_float(right),
    do: :math.fmod(left, right) |> Float.round(5)

  def modulo(left, right, _), do: rem(left, right)

  @doc """
  Replaces every newline (\n) in a string with an HTML line break (<br />).

  ## Examples

      iex> Liquex.Filter.newline_to_br("\\nHello\\nthere\\n", %{})
      "<br />\\nHello<br />\\nthere<br />\\n"
  """
  @spec newline_to_br(String.t(), Context.t()) :: String.t()
  def newline_to_br(value, _), do: String.replace(value, "\n", "<br />\n")

  @doc """
  Adds a number to another number.

  ## Examples

      iex> Liquex.Filter.plus(4, 2, %{})
      6

      iex> Liquex.Filter.plus(183.357, 12, %{})
      195.357
  """
  def plus(left, right, _), do: left + right

  @doc """
  Adds the specified string to the beginning of another string.

  ## Examples

      iex> Liquex.Filter.prepend("apples, oranges, and bananas", "Some fruit: ", %{})
      "Some fruit: apples, oranges, and bananas"

      iex> Liquex.Filter.prepend("/index.html", "example.com", %{})
      "example.com/index.html"
  """
  def prepend(value, prepender, _), do: prepender <> value

  @doc """
  Removes every occurrence of the specified substring from a string.

  ## Examples

      iex> Liquex.Filter.remove("I strained to see the train through the rain", "rain", %{})
      "I sted to see the t through the "
  """
  def remove(value, original, context), do: replace(value, original, "", context)

  @doc """
  Removes every occurrence of the specified substring from a string.

  ## Examples

      iex> Liquex.Filter.remove_first("I strained to see the train through the rain", "rain", %{})
      "I sted to see the train through the rain"
  """
  def remove_first(value, original, context), do: replace_first(value, original, "", context)

  @doc """
  Replaces every occurrence of the first argument in a string with the second argument.

  ## Examples

      iex> Liquex.Filter.replace("Take my protein pills and put my helmet on", "my", "your", %{})
      "Take your protein pills and put your helmet on"
  """
  def replace(value, original, replacement, _),
    do: String.replace(value, original, replacement)

  @doc """
  Replaces only the first occurrence of the first argument in a string with the second argument.

  ## Examples

      iex> Liquex.Filter.replace_first("Take my protein pills and put my helmet on", "my", "your", %{})
      "Take your protein pills and put my helmet on"
  """
  def replace_first(value, original, replacement, _),
    do: String.replace(value, original, replacement, global: false)

  @doc """
  Reverses the order of the items in an array. reverse cannot reverse a string.

  ## Examples

      iex> Liquex.Filter.reverse(~w(apples oranges peaches plums), %{})
      ["plums", "peaches", "oranges", "apples"]
  """
  def reverse(arr, _) when is_list(arr), do: Enum.reverse(arr)

  @doc """
  Rounds a number to the nearest integer or, if a number is passed as an argument, to that number of decimal places.

  ## Examples

      iex> Liquex.Filter.round(1, %{})
      1

      iex> Liquex.Filter.round(1.2, %{})
      1

      iex> Liquex.Filter.round(2.7, %{})
      3

      iex> Liquex.Filter.round(183.357, 2, %{})
      183.36
  """
  def round(value, precision \\ 0, context)
  def round(value, _, _) when is_integer(value), do: value
  def round(value, 0, _), do: value |> Float.round() |> trunc()
  def round(value, precision, _), do: Float.round(value, precision)

  @doc """
  Removes all whitespace (tabs, spaces, and newlines) from the right side of a string.
  It does not affect spaces between words.

  ## Examples

      iex> Liquex.Filter.rstrip("          So much room for activities!          ", %{})
      "          So much room for activities!"
  """
  def rstrip(value, _), do: value |> String.trim_trailing()

  @doc """
  Returns the number of characters in a string or the number of items in an array.

  ## Examples

      iex> Liquex.Filter.size("Ground control to Major Tom.", %{})
      28

      iex> Liquex.Filter.size(~w(apples oranges peaches plums), %{})
      4
  """
  def size(value, _) when is_list(value), do: length(value)
  def size(value, _) when is_binary(value), do: String.length(value)

  @doc """
  Returns a substring of 1 character beginning at the index specified by the
  first argument. An optional second argument specifies the length of the
  substring to be returned.

  ## Examples

      iex> Liquex.Filter.slice("Liquid", 0, %{})
      "L"

      iex> Liquex.Filter.slice("Liquid", 2, %{})
      "q"

      iex> Liquex.Filter.slice("Liquid", 2, 5, %{})
      "quid"

  If the first argument is a negative number, the indices are counted from
  the end of the string:

  ## Examples

      iex> Liquex.Filter.slice("Liquid", -3, 2, %{})
      "ui"
  """
  def slice(value, start, length \\ 1, _),
    do: String.slice(value, start, length)

  @doc """
  Sorts items in an array in case-sensitive order.

  ## Examples

      iex> Liquex.Filter.sort(["zebra", "octopus", "giraffe", "Sally Snake"], %{})
      ["Sally Snake", "giraffe", "octopus", "zebra"]
  """
  def sort(list, _), do: Liquex.Collection.sort(list)
  def sort(list, field_name, _), do: Liquex.Collection.sort(list, field_name)

  @doc """
  Sorts items in an array in case-insensitive order.

  ## Examples

      iex> Liquex.Filter.sort_natural(["zebra", "octopus", "giraffe", "Sally Snake"], %{})
      ["giraffe", "octopus", "Sally Snake", "zebra"]
  """
  def sort_natural(list, _), do: Liquex.Collection.sort_case_insensitive(list)

  def sort_natural(list, field_name, _),
    do: Liquex.Collection.sort_case_insensitive(list, field_name)

  @doc """
  Divides a string into an array using the argument as a separator. split is
  commonly used to convert comma-separated items from a string to an array.

  ## Examples

      iex> Liquex.Filter.split("John, Paul, George, Ringo", ", ", %{})
      ["John", "Paul", "George", "Ringo"]
  """
  def split(value, separator, _), do: String.split(value, separator)

  @doc """
  Removes all whitespace (tabs, spaces, and newlines) from both the left and
  right side of a string. It does not affect spaces between words.

  ## Examples

      iex> Liquex.Filter.strip("          So much room for activities!          ", %{})
      "So much room for activities!"
  """
  def strip(value, _), do: String.trim(value)

  @doc """
  Removes any HTML tags from a string.

  ## Examples

      iex> Liquex.Filter.strip_html("Have <em>you</em> read <strong>Ulysses</strong>?", %{})
      "Have you read Ulysses?"
  """
  def strip_html(value, _), do: HtmlSanitizeEx.strip_tags(value)

  @doc """
  Removes any newline characters (line breaks) from a string.

  ## Examples

      iex> Liquex.Filter.strip_newlines("Hello\\nthere", %{})
      "Hellothere"
  """
  def strip_newlines(value, _) do
    value
    |> String.replace("\r", "")
    |> String.replace("\n", "")
  end

  @doc """
  Multiplies a number by another number.

  ## Examples

      iex> Liquex.Filter.times(3, 4, %{})
      12

      iex> Liquex.Filter.times(24, 7, %{})
      168

      iex> Liquex.Filter.times(183.357, 12, %{})
      2200.284
  """
  def times(value, divisor, _), do: value * divisor

  @doc """
  Shortens a string down to the number of characters passed as an argument. If
  the specified number of characters is less than the length of the string, an
  ellipsis (…) is appended to the string and is included in the character
  count.

  ## Examples

      iex> Liquex.Filter.truncate("Ground control to Major Tom.", 20, %{})
      "Ground control to..."

      iex> Liquex.Filter.truncate("Ground control to Major Tom.", 25, ", and so on", %{})
      "Ground control, and so on"

      iex> Liquex.Filter.truncate("Ground control to Major Tom.", 20, "", %{})
      "Ground control to Ma"
  """
  def truncate(value, length, ellipsis \\ "...", _) do
    if String.length(value) <= length do
      value
    else
      String.slice(
        value,
        0,
        length - String.length(ellipsis)
      ) <> ellipsis
    end
  end

  @doc """
  Shortens a string down to the number of characters passed as an argument. If
  the specified number of characters is less than the length of the string, an
  ellipsis (…) is appended to the string and is included in the character
  count.

  ## Examples

      iex> Liquex.Filter.truncatewords("Ground control to Major Tom.", 3, %{})
      "Ground control to..."

      iex> Liquex.Filter.truncatewords("Ground control to Major Tom.", 3, "--", %{})
      "Ground control to--"

      iex> Liquex.Filter.truncatewords("Ground control to Major Tom.", 3, "", %{})
      "Ground control to"
  """
  def truncatewords(value, length, ellipsis \\ "...", _) do
    words = value |> String.split()

    if length(words) <= length do
      value
    else
      sentence =
        words
        |> Enum.take(length)
        |> Enum.join(" ")

      sentence <> ellipsis
    end
  end

  @doc """
  Removes any duplicate elements in an array.

  ## Examples

      iex> Liquex.Filter.uniq(~w(ants bugs bees bugs ants), %{})
      ["ants", "bugs", "bees"]
  """
  def uniq(list, _), do: Enum.uniq(list)

  @doc """
  Makes each character in a string uppercase. It has no effect on strings
  which are already all uppercase.

  ## Examples

      iex> Liquex.Filter.upcase("Parker Moore", %{})
      "PARKER MOORE"

      iex> Liquex.Filter.upcase("APPLE", %{})
      "APPLE"
  """
  def upcase(value, _), do: String.upcase(value)

  @doc """
  Decodes a string that has been encoded as a URL or by url_encode/2.

  ## Examples

      iex> Liquex.Filter.url_decode("%27Stop%21%27+said+Fred", %{})
      "'Stop!' said Fred"
  """
  def url_decode(value, _), do: URI.decode_www_form(value)

  @doc """
  Decodes a string that has been encoded as a URL or by url_encode/2.

  ## Examples

      iex> Liquex.Filter.url_encode("john@liquid.com", %{})
      "john%40liquid.com"

      iex> Liquex.Filter.url_encode("Tetsuro Takara", %{})
      "Tetsuro+Takara"
  """
  def url_encode(value, _), do: URI.encode_www_form(value)

  @doc """
  Creates an array including only the objects with a given property value, or
  any truthy value by default.

  ## Examples

      iex> Liquex.Filter.where([%{"b" => 2}, %{"b" => 1}], "b", 1, %{})
      [%{"b" => 1}]
  """
  def where(list, key, value, _), do: Liquex.Collection.where(list, key, value)

  @doc """
  Creates an array including only the objects with a given truthy property value

  ## Examples

      iex> Liquex.Filter.where([%{"b" => true, "value" => 1}, %{"b" => 1, "value" => 2}, %{"b" => false, "value" => 3}], "b", %{})
      [%{"b" => true, "value" => 1}, %{"b" => 1, "value" => 2}]
  """
  def where(list, key, _), do: Liquex.Collection.where(list, key)
end
