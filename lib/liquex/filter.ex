defmodule Liquex.Filter do
  @moduledoc """
  Contains all the basic filters for Liquid
  """

  @type filter_t :: {:filter, [...]}
  @callback apply(any, filter_t, map) :: any

  alias Liquex.Context
  alias Liquex.Math

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

    # Liquid's filters operate on Ruby Arrays; ranges go through `to_a` first.
    Kernel.apply(mod, func, [normalize(value) | function_args] ++ [context])
  rescue
    # credo:disable-for-next-line
    ArgumentError -> raise Liquex.Error, "Invalid filter #{function}"
  end

  defp normalize(%Range{} = r), do: Enum.to_list(r)
  defp normalize(value), do: value

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
  @spec abs(String.t() | number | Decimal.t() | nil, any) :: number | Decimal.t()
  def abs(value, _), do: Math.absolute(to_number(value))

  @doc """
  Appends `text` to the end of `value`

  ## Examples

      iex> Liquex.Filter.append("myfile", ".html", %{})
      "myfile.html"
  """
  @spec append(String.t(), String.t(), map()) :: String.t()
  def append(value, text, _), do: to_string(value) <> to_string(text)

  @doc """
  Sets a minimum value

  ## Examples

      iex> Liquex.Filter.at_least(3, 5, %{})
      5

      iex> Liquex.Filter.at_least(5, 3, %{})
      5

      iex> Liquex.Filter.at_least("5", "3", %{})
      5
  """
  @spec at_least(number | binary, number | binary, map()) :: number | Decimal.t()
  def at_least(value, max, _), do: do_at_least(to_number(value), to_number(max))

  defp do_at_least(v, m) do
    cond do
      Math.nan?(v) -> m
      Math.nan?(m) -> v
      Math.special?(v) or Math.special?(m) ->
        if Math.compare(v, m) == :gt, do: v, else: m

      v > m ->
        v

      true ->
        m
    end
  end

  @doc """
  Sets a maximum value

  ## Examples

      iex> Liquex.Filter.at_most(4, 5, %{})
      4

      iex> Liquex.Filter.at_most(4, 3, %{})
      3

      iex> Liquex.Filter.at_most("4", "3", %{})
      3
  """
  @spec at_most(number, number, map()) :: number | Decimal.t()
  def at_most(value, max, _), do: do_at_most(to_number(value), to_number(max))

  defp do_at_most(v, m) do
    cond do
      Math.nan?(v) -> m
      Math.nan?(m) -> v
      Math.special?(v) or Math.special?(m) ->
        if Math.compare(v, m) == :lt, do: v, else: m

      v < m ->
        v

      true ->
        m
    end
  end

  @doc """
  Encodes a string into base 64.

  ## Examples

      iex> Liquex.Filter.base64_encode("_hello_", %{})
      "X2hlbGxvXw=="
  """
  @spec base64_encode(String.t() | nil, map()) :: String.t()
  def base64_encode(value, _), do: value |> to_string() |> Base.encode64()

  @doc """
  Decodes a base 64 string.

  ## Examples

      iex> Liquex.Filter.base64_decode("X2hlbGxvXw==", %{})
      "_hello_"
  """
  @spec base64_decode(String.t() | nil, map()) :: String.t()
  def base64_decode(value, _) do
    case value |> to_string() |> Base.decode64() do
      {:ok, decoded} -> decoded
      :error -> raise Liquex.Error, "invalid base64 provided to base64_decode"
    end
  end

  @doc """
  Encodes a string into URL-safe base 64.

  ## Examples

      iex> Liquex.Filter.base64_url_safe_encode("_hello world?+/", %{})
      "X2hlbGxvIHdvcmxkPysv"
  """
  @spec base64_url_safe_encode(String.t() | nil, map()) :: String.t()
  def base64_url_safe_encode(value, _), do: value |> to_string() |> Base.url_encode64()

  @doc """
  Decodes a URL-safe base 64 string.

  ## Examples

      iex> Liquex.Filter.base64_url_safe_decode("X2hlbGxvIHdvcmxkPysv", %{})
      "_hello world?+/"
  """
  @spec base64_url_safe_decode(String.t() | nil, map()) :: String.t()
  def base64_url_safe_decode(value, _) do
    case value |> to_string() |> Base.url_decode64() do
      {:ok, decoded} -> decoded
      :error -> raise Liquex.Error, "invalid base64 provided to base64_url_safe_decode"
    end
  end

  @doc """
  Capitalizes a string

  ## Examples

      iex> Liquex.Filter.capitalize("title", %{})
      "Title"

      iex> Liquex.Filter.capitalize("my great title", %{})
      "My great title"
  """
  @spec capitalize(String.t(), map()) :: String.t()
  def capitalize(value, _), do: String.capitalize(to_string(value))

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
  @spec ceil(number | String.t() | nil, map()) :: number
  def ceil(value, ctx) when is_binary(value), do: value |> to_number() |> ceil(ctx)
  def ceil(value, _) when is_float(value), do: Float.ceil(value) |> trunc()
  def ceil(value, _) when is_integer(value), do: value
  def ceil(nil, _), do: 0

  def ceil(%Decimal{coef: c} = d, _) when c in [:inf, :NaN, :qNaN, :sNaN],
    do: Math.computation_error(d)

  def ceil(%Decimal{} = d, _),
    do: d |> Decimal.round(0, :ceiling) |> Decimal.to_integer()

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
  Removes any items in the array whose `property` is `nil`.

  ## Examples

      iex> Liquex.Filter.compact([%{"a" => 1}, %{"a" => nil}, %{"a" => 2}], "a", %{})
      [%{"a" => 1}, %{"a" => 2}]
  """
  def compact(value, property, _) when is_list(value),
    do: Enum.reject(value, &is_nil(Liquex.Indifferent.get(&1, property)))

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
  def date(%Date{} = value, format, _), do: Calendar.strftime(value, format)
  def date(%DateTime{} = value, format, _), do: Calendar.strftime(value, format)
  def date(%NaiveDateTime{} = value, format, _), do: Calendar.strftime(value, format)

  def date(value, format, context) when value in ["now", "today"],
    do: date(now_in_zone(context), format, context)

  def date(value, format, context) when is_integer(value),
    do: date(unix_in_zone(value, context), format, context)

  def date(value, format, context) when is_binary(value) do
    # Thanks to the nonspecific definition of the format in the spec, we parse
    # some common date formats. Keep the full datetime (hours/minutes/etc.) so
    # format directives like `%H` work; previously we degraded to a Date and
    # crashed when the format asked for time fields.
    case DateTimeParser.parse_datetime(value, assume_time: true) do
      {:ok, parsed} -> date(parsed, format, context)
      _ -> nil
    end
  end

  def date(nil, _, _), do: nil

  # `'now'` / `'today'` and integer Unix timestamps render in the host's local
  # timezone by default (matching Ruby's `Time.now`/`Time.at`, which honor
  # `ENV['TZ']`). Set `Liquex.Context.new(.., timezone: "America/New_York")` to
  # override -- requires a `tzdata`-backed `TimeZoneDatabase`.
  defp now_in_zone(%Liquex.Context{timezone: nil}) do
    utc = :calendar.universal_time()
    build_local_datetime(:calendar.local_time(), utc)
  end

  defp now_in_zone(%Liquex.Context{timezone: tz}) do
    case DateTime.now(tz) do
      {:ok, dt} -> dt
      {:error, reason} -> raise_tz_error(tz, reason)
    end
  end

  defp now_in_zone(_), do: now_in_zone(%Liquex.Context{})

  defp unix_in_zone(value, %Liquex.Context{timezone: nil}) do
    utc_erl = DateTime.from_unix!(value) |> DateTime.to_naive() |> NaiveDateTime.to_erl()
    local_erl = :calendar.universal_time_to_local_time(utc_erl)
    build_local_datetime(local_erl, utc_erl)
  end

  defp unix_in_zone(value, %Liquex.Context{timezone: tz}) do
    case value |> DateTime.from_unix!() |> DateTime.shift_zone(tz) do
      {:ok, dt} -> dt
      {:error, reason} -> raise_tz_error(tz, reason)
    end
  end

  defp unix_in_zone(value, _), do: unix_in_zone(value, %Liquex.Context{})

  defp raise_tz_error(tz, :utc_only_time_zone_database) do
    raise Liquex.Error,
          "Cannot use timezone #{inspect(tz)}: no tzdata-backed time zone " <>
            "database is configured. Add `{:tzdata, \"~> 1.1\"}` and call " <>
            "`Calendar.put_time_zone_database(Tzdata.TimeZoneDatabase)`."
  end

  defp raise_tz_error(tz, reason),
    do: raise(Liquex.Error, "Cannot resolve timezone #{inspect(tz)}: #{inspect(reason)}")

  defp build_local_datetime({{y, mo, d}, {h, mi, s}} = local_erl, utc_erl) do
    offset =
      :calendar.datetime_to_gregorian_seconds(local_erl) -
        :calendar.datetime_to_gregorian_seconds(utc_erl)

    %DateTime{
      year: y,
      month: mo,
      day: d,
      hour: h,
      minute: mi,
      second: s,
      microsecond: {0, 0},
      time_zone: System.get_env("TZ") || "Etc/Local",
      zone_abbr: "",
      utc_offset: offset,
      std_offset: 0,
      calendar: Calendar.ISO
    }
  end

  @doc """
  Allows you to specify a fallback in case a value doesn’t exist. default will show its value
  if the left side is nil, false, or empty.

  ## Examples

      iex> Liquex.Filter.default("1.99", "2.99", %{})
      "1.99"

      iex> Liquex.Filter.default("", "2.99", %{})
      "2.99"

      iex> Liquex.Filter.default(false, "x", [{"allow_false", true}], %{})
      false

      iex> Liquex.Filter.default(false, "x", [{"allow_false", false}], %{})
      "x"
  """
  def default(value, def_value, _) when value in [nil, "", false, []], do: def_value
  def default(value, _, _), do: value

  def default(value, def_value, options, context) when is_list(options) do
    case Enum.find(options, fn
           {"allow_false", _} -> true
           _ -> false
         end) do
      {"allow_false", true} when value == false -> false
      _ -> default(value, def_value, context)
    end
  end

  @doc """
  Divides a number by another number.

  ## Examples

  The result is rounded down to the nearest integer (that is, the floor) if the divisor is an integer.

      iex> Liquex.Filter.divided_by(16, 4, %{})
      4

      iex> Liquex.Filter.divided_by(5, 3, %{})
      1

      iex> Liquex.Filter.divided_by(20, 5, %{})
      4

      iex> Decimal.equal?(Liquex.Filter.divided_by(20, 7.0, %{}), Decimal.new("2.857142857142857142857142857"))
      true
  """
  def divided_by(value, divisor, _) do
    case Math.divide(to_number(value), to_number(divisor)) do
      {:zero_division} -> "Liquid error: divided by 0"
      result -> result
    end
  end

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
  def downcase(value, _), do: String.downcase(to_string(value))

  @doc """
  Escapes a string by replacing characters with escape sequences (so that the string can
  be used in a URL, for example). It doesn’t change strings that don’t have anything to
  escape.

  ## Examples

      iex> Liquex.Filter.escape("Have you read 'James & the Giant Peach'?", %{})
      "Have you read &#39;James &amp; the Giant Peach&#39;?"

      iex> Liquex.Filter.escape("Tetsuro Takara", %{})
      "Tetsuro Takara"
  """
  def escape(value, _) do
    to_string(value)
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end

  @doc """
  Escapes a string by replacing characters with escape sequences (so that the string can
  be used in a URL, for example). It doesn’t change strings that don’t have anything to
  escape.

  ## Examples

      iex> Liquex.Filter.escape_once("1 &lt; 2 &amp; 3", %{})
      "1 &lt; 2 &amp; 3"
  """
  def escape_once(value, _) do
    Regex.replace(
      ~r/["><']|&(?!([a-zA-Z]+|(#\d+));)/,
      to_string(value),
      &escape_char/1
    )
  end

  defp escape_char("&"), do: "&amp;"
  defp escape_char("<"), do: "&lt;"
  defp escape_char(">"), do: "&gt;"
  defp escape_char("\""), do: "&quot;"
  defp escape_char("'"), do: "&#39;"

  @doc """
  Returns the first item in an array whose `property` is truthy. Returns `nil`
  if no item matches or the array is empty.

  ## Examples

      iex> Liquex.Filter.find([%{"v" => 1}, %{"v" => 2}], "v", 2, %{})
      %{"v" => 2}

      iex> Liquex.Filter.find([%{"v" => 1}, %{"v" => 2}], "v", %{})
      %{"v" => 1}

      iex> Liquex.Filter.find([], "v", 2, %{})
      nil
  """
  def find(list, property, _) when is_list(list),
    do: Enum.find(list, &property_truthy?(&1, property))

  def find(list, property, target_value, _) when is_list(list),
    do: Enum.find(list, &property_equals?(&1, property, target_value))

  @doc """
  Returns the index of the first item in an array whose `property` is truthy or
  matches `target_value`. Returns `nil` if no item matches or the array is empty.

  ## Examples

      iex> Liquex.Filter.find_index([%{"v" => 1}, %{"v" => 2}], "v", 2, %{})
      1

      iex> Liquex.Filter.find_index([%{"v" => 1}, %{"v" => 2}], "v", %{})
      0

      iex> Liquex.Filter.find_index([], "v", 2, %{})
      nil
  """
  def find_index(list, property, _) when is_list(list),
    do: Enum.find_index(list, &property_truthy?(&1, property))

  def find_index(list, property, target_value, _) when is_list(list),
    do: Enum.find_index(list, &property_equals?(&1, property, target_value))

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
  def first(_, _), do: nil

  @doc """
  Rounds the input down to the nearest whole number. Liquid tries to convert the input to a
  number before the filter is applied.

  ## Examples

      iex> Liquex.Filter.floor(1.2, %{})
      1

      iex> Liquex.Filter.floor(2.0, %{})
      2
  """
  @spec floor(binary | number | Decimal.t() | nil, any) :: integer | binary
  def floor(value, _) do
    case to_number(value) do
      %Decimal{coef: c} = d when c in [:inf, :NaN, :qNaN, :sNaN] ->
        Math.computation_error(d)

      %Decimal{} = d ->
        d |> Decimal.round(0, :floor) |> Decimal.to_integer()

      n ->
        trunc(n)
    end
  end

  @doc """
  Combines the items in `values` into a single string using `joiner` as a separator.

  ## Examples

      iex> Liquex.Filter.join(~w(John Paul George Ringo), " and ", %{})
      "John and Paul and George and Ringo"
  """
  def join(values, joiner, _), do: Enum.join(values, joiner)

  @doc """
  Returns `true` if any item in the array has the given `property` truthy or
  matching `target_value`, otherwise `false`. Returns `false` for empty arrays.

  ## Examples

      iex> Liquex.Filter.has([%{"v" => 1}, %{"v" => 2}], "v", 2, %{})
      true

      iex> Liquex.Filter.has([%{"v" => 1}], "v", 99, %{})
      false

      iex> Liquex.Filter.has([], "v", 2, %{})
      false
  """
  def has(list, property, _) when is_list(list),
    do: Enum.any?(list, &property_truthy?(&1, property))

  def has(list, property, target_value, _) when is_list(list),
    do: Enum.any?(list, &property_equals?(&1, property, target_value))

  @doc """
  Returns the last item of `arr`.

  ## Examples

      iex> Liquex.Filter.last([1, 2, 3], %{})
      3

      iex> Liquex.Filter.first([], %{})
      nil
  """
  @spec last(any, Liquex.Context.t()) :: any
  def last(arr, context) when is_list(arr), do: arr |> Enum.reverse() |> first(context)
  def last(_, _), do: nil

  @doc """
  Removes all whitespace (tabs, spaces, and newlines) from the left side of a string.
  It does not affect spaces between words.

  ## Examples

      iex> Liquex.Filter.lstrip("          So much room for activities!          ", %{})
      "So much room for activities!          "
  """
  @spec lstrip(String.t(), Context.t()) :: String.t()
  def lstrip(value, _), do: to_string(value) |> String.trim_leading()

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

      iex> Liquex.Filter.minus(183, 12, %{})
      171

      iex> Decimal.equal?(Liquex.Filter.minus(183.357, 12, %{}), Decimal.new("171.357"))
      true
  """
  @spec minus(number | nil, number | nil, Context.t()) :: number
  def minus(left, right, _), do: Math.sub(to_number(left), to_number(right))

  @doc """
  Returns the remainder of a division operation.

  ## Examples

      iex> Liquex.Filter.modulo(3, 2, %{})
      1

      iex> Liquex.Filter.modulo(183, 12, %{})
      3

      iex> Decimal.equal?(Liquex.Filter.modulo(10.5, 3, %{}), Decimal.new("1.5"))
      true
  """
  @spec modulo(number | nil, number | nil, Context.t()) :: number
  def modulo(left, right, _) do
    case Math.modulo(to_number(left), to_number(right)) do
      {:zero_division} -> "Liquid error: divided by 0"
      result -> result
    end
  end

  @doc """
  Replaces every newline (\n) in a string with an HTML line break (<br />).

  ## Examples

      iex> Liquex.Filter.newline_to_br("\\nHello\\nthere\\n", %{})
      "<br />\\nHello<br />\\nthere<br />\\n"
  """
  @spec newline_to_br(String.t(), Context.t()) :: String.t()
  def newline_to_br(value, _), do: String.replace(to_string(value), "\n", "<br />\n")

  @doc """
  Adds a number to another number.

  ## Examples

      iex> Liquex.Filter.plus(4, 2, %{})
      6

      iex> Liquex.Filter.plus(183, 12, %{})
      195

      iex> Decimal.equal?(Liquex.Filter.plus(0.1, 0.2, %{}), Decimal.new("0.3"))
      true

      iex> Decimal.equal?(Liquex.Filter.plus(9.99, 14.5, %{}), Decimal.new("24.49"))
      true
  """
  @spec plus(number | nil, number | nil, Context.t()) :: number
  def plus(left, right, _), do: Math.add(to_number(left), to_number(right))

  @doc """
  Adds the specified string to the beginning of another string.

  ## Examples

      iex> Liquex.Filter.prepend("apples, oranges, and bananas", "Some fruit: ", %{})
      "Some fruit: apples, oranges, and bananas"

      iex> Liquex.Filter.prepend("/index.html", "example.com", %{})
      "example.com/index.html"
  """
  def prepend(value, prepender, _), do: to_string(prepender) <> to_string(value)

  @doc """
  Returns the items of an array whose `property` is falsy, or whose `property`
  is not equal to `target_value` when given.

  ## Examples

      iex> Liquex.Filter.reject([%{"v" => 1}, %{"v" => 2}, %{"v" => 3}], "v", 2, %{})
      [%{"v" => 1}, %{"v" => 3}]

      iex> Liquex.Filter.reject([%{"a" => true}, %{"a" => false}], "a", %{})
      [%{"a" => false}]
  """
  def reject(list, property, _) when is_list(list),
    do: Enum.reject(list, &property_truthy?(&1, property))

  def reject(list, property, target_value, _) when is_list(list),
    do: Enum.reject(list, &property_equals?(&1, property, target_value))

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
  Removes only the last occurrence of the specified substring from a string.

  ## Examples

      iex> Liquex.Filter.remove_last("I strained to see the train through the rain", "rain", %{})
      "I strained to see the train through the "
  """
  def remove_last(value, original, context), do: replace_last(value, original, "", context)

  @doc """
  Replaces every occurrence of the first argument in a string with the second argument.

  ## Examples

      iex> Liquex.Filter.replace("Take my protein pills and put my helmet on", "my", "your", %{})
      "Take your protein pills and put your helmet on"
  """
  def replace(value, original, replacement, _),
    do: String.replace(to_string(value), to_string(original), to_string(replacement))

  @doc """
  Replaces only the first occurrence of the first argument in a string with the second argument.

  ## Examples

      iex> Liquex.Filter.replace_first("Take my protein pills and put my helmet on", "my", "your", %{})
      "Take your protein pills and put my helmet on"
  """
  def replace_first(value, original, replacement, _),
    do:
      String.replace(to_string(value), to_string(original), to_string(replacement), global: false)

  @doc """
  Replaces only the last occurrence of the first argument in a string with the
  second argument. Returns the input unchanged if no occurrence is found.

  ## Examples

      iex> Liquex.Filter.replace_last("red, red, red", "red", "blue", %{})
      "red, red, blue"

      iex> Liquex.Filter.replace_last("abc", "x", "y", %{})
      "abc"
  """
  def replace_last(value, original, replacement, _) do
    input = to_string(value)
    search = to_string(original)
    repl = to_string(replacement)

    case String.split(input, search) do
      [_only] ->
        input

      parts ->
        {leading, [tail]} = Enum.split(parts, length(parts) - 1)
        Enum.join(leading, search) <> repl <> tail
    end
  end

  @doc """
  Reverses the order of the items in an array. reverse cannot reverse a string.

  ## Examples

      iex> Liquex.Filter.reverse(~w(apples oranges peaches plums), %{})
      ["plums", "peaches", "oranges", "apples"]
  """
  def reverse(arr, _) when is_list(arr), do: Enum.reverse(arr)
  def reverse(value, _), do: value

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

      iex> Liquex.Filter.round(183.357, "invalid", %{})
      183

      iex> Liquex.Filter.round(183.357, 0, %{})
      183

      iex> Liquex.Filter.round(1234, -2, %{})
      1200

      iex> Liquex.Filter.round(183.357, -1, %{})
      180
  """
  @spec round(binary | number | nil, binary | number | nil, Context.t()) :: number
  def round(value, precision \\ 0, _context),
    do: do_round(to_number(value), to_number(precision))

  defp do_round(%Decimal{coef: c} = d, _) when c in [:inf, :NaN, :qNaN, :sNaN],
    do: Math.computation_error(d)

  # Finite Decimal inputs typically come from prior arithmetic; convert to
  # float for the rounding to mirror Liquid's BigDecimal -> Float -> round.
  defp do_round(%Decimal{} = d, precision),
    do: do_round(Decimal.to_float(d), precision)

  defp do_round(value, precision) when precision < 0 do
    factor = trunc(:math.pow(10, -precision))
    Kernel.round(value / factor) * factor
  end

  defp do_round(value, _) when is_integer(value), do: value
  defp do_round(value, 0), do: Float.round(value) |> trunc()
  defp do_round(value, precision), do: Float.round(value, precision)

  @doc """
  Removes all whitespace (tabs, spaces, and newlines) from the right side of a string.
  It does not affect spaces between words.

  ## Examples

      iex> Liquex.Filter.rstrip("          So much room for activities!          ", %{})
      "          So much room for activities!"
  """
  def rstrip(value, _), do: to_string(value) |> String.trim_trailing()

  @doc """
  Returns the number of characters in a string or the number of items in an array.

  ## Examples

      iex> Liquex.Filter.size("Ground control to Major Tom.", %{})
      28

      iex> Liquex.Filter.size(~w(apples oranges peaches plums), %{})
      4
  """
  def size(value, _) when is_list(value), do: length(value)
  def size(value, _) when is_map(value) and not is_struct(value), do: map_size(value)
  def size(value, _), do: String.length(to_string(value))

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

  Slicing an array returns a sub-array.

  ## Examples

      iex> Liquex.Filter.slice([1, 2, 3, 4, 5], 1, 2, %{})
      [2, 3]

      iex> Liquex.Filter.slice([1, 2, 3, 4, 5], 2, %{})
      [3]
  """
  def slice(value, start, length \\ 1, _)

  def slice(value, start, length, _) when is_list(value),
    do: Enum.slice(value, start, length)

  def slice(value, start, length, _),
    do: String.slice(to_string(value), start, length)

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
  def split(value, separator, _), do: String.split(to_string(value), to_string(separator))

  @doc """
  Removes all whitespace (tabs, spaces, and newlines) from both the left and
  right side of a string. It does not affect spaces between words.

  ## Examples

      iex> Liquex.Filter.strip("          So much room for activities!          ", %{})
      "So much room for activities!"
  """
  def strip(value, _), do: String.trim(to_string(value))

  @doc """
  Removes any HTML tags from a string. The contents of `<script>`, `<style>`,
  and HTML comments are stripped along with the tags themselves, matching the
  Liquid gem's `strip_html` behavior.

  ## Examples

      iex> Liquex.Filter.strip_html("Have <em>you</em> read <strong>Ulysses</strong>?", %{})
      "Have you read Ulysses?"

      iex> Liquex.Filter.strip_html("<script>alert(1)</script>hi", %{})
      "hi"

      iex> Liquex.Filter.strip_html("<style>p {}</style>hi", %{})
      "hi"

      iex> Liquex.Filter.strip_html("a<!-- gone -->b", %{})
      "ab"
  """
  def strip_html(value, _) do
    to_string(value)
    |> String.replace(~r/<script.*?<\/script>/s, "")
    |> String.replace(~r/<!--.*?-->/s, "")
    |> String.replace(~r/<style.*?<\/style>/s, "")
    |> String.replace(~r/<.*?>/s, "")
  end

  @doc """
  Removes any newline characters (line breaks) from a string.

  ## Examples

      iex> Liquex.Filter.strip_newlines("Hello\\nthere", %{})
      "Hellothere"
  """
  def strip_newlines(value, _) do
    to_string(value)
    |> String.replace("\r", "")
    |> String.replace("\n", "")
  end

  @doc """
  Returns the sum of the items in an array. Items are coerced to numbers; with
  a `property` argument, the named property of each item is summed instead.

  ## Examples

      iex> Liquex.Filter.sum([1, 2, 3], %{})
      6

      iex> Liquex.Filter.sum([%{"v" => 1}, %{"v" => 2}], "v", %{})
      3

      iex> Liquex.Filter.sum([], %{})
      0
  """
  def sum(list, _) when is_list(list),
    do: Enum.reduce(list, 0, fn item, acc -> Math.add(acc, to_number(item)) end)

  def sum(list, property, _) when is_list(list) do
    Enum.reduce(list, 0, fn item, acc ->
      value =
        cond do
          is_map(item) -> Liquex.Indifferent.get(item, property, 0)
          true -> 0
        end

      Math.add(acc, to_number(value))
    end)
  end

  @doc """
  Multiplies a number by another number.

  ## Examples

      iex> Liquex.Filter.times(3, 4, %{})
      12

      iex> Liquex.Filter.times(24, 7, %{})
      168

      iex> Liquex.Filter.times(7, 12, %{})
      84

      iex> Decimal.equal?(Liquex.Filter.times(9.99, 2, %{}), Decimal.new("19.98"))
      true
  """
  def times(value, divisor, _), do: Math.mul(to_number(value), to_number(divisor))

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
    value = to_string(value)

    if String.length(value) <= length do
      value
    else
      slice_length = max(length - String.length(ellipsis), 0)
      String.slice(value, 0, slice_length) <> ellipsis
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

      iex> Liquex.Filter.truncatewords("a b c d e", 0, %{})
      "a..."
  """
  def truncatewords(value, length, ellipsis \\ "...", _) do
    value = to_string(value)
    length = max(to_number(length), 1)
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
  Removes items from an array that share a value at the given `property`.

  ## Examples

      iex> Liquex.Filter.uniq([%{"id" => 1}, %{"id" => 2}, %{"id" => 1}], "id", %{})
      [%{"id" => 1}, %{"id" => 2}]
  """
  def uniq(list, property, _) when is_list(list),
    do: Enum.uniq_by(list, &Liquex.Indifferent.get(&1, property))

  @doc """
  Makes each character in a string uppercase. It has no effect on strings
  which are already all uppercase.

  ## Examples

      iex> Liquex.Filter.upcase("Parker Moore", %{})
      "PARKER MOORE"

      iex> Liquex.Filter.upcase("APPLE", %{})
      "APPLE"
  """
  def upcase(value, _), do: String.upcase(to_string(value))

  @doc """
  Decodes a string that has been encoded as a URL or by url_encode/2.

  ## Examples

      iex> Liquex.Filter.url_decode("%27Stop%21%27+said+Fred", %{})
      "'Stop!' said Fred"
  """
  def url_decode(value, _), do: URI.decode_www_form(to_string(value))

  @doc """
  Decodes a string that has been encoded as a URL or by url_encode/2.

  ## Examples

      iex> Liquex.Filter.url_encode("john@liquid.com", %{})
      "john%40liquid.com"

      iex> Liquex.Filter.url_encode("Tetsuro Takara", %{})
      "Tetsuro+Takara"
  """
  def url_encode(value, _), do: URI.encode_www_form(to_string(value))

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

  # Predicates shared by find/find_index/has/reject (Liquid's filter_array helper).
  defp property_truthy?(item, property) when is_map(item) do
    case Liquex.Indifferent.get(item, property) do
      nil -> false
      false -> false
      _ -> true
    end
  end

  defp property_truthy?(_item, _property), do: false

  defp property_equals?(item, property, target) when is_map(item),
    do: Liquex.Indifferent.get(item, property) == target

  defp property_equals?(_item, _property, _target), do: false

  defp to_number(nil), do: 0
  defp to_number(%Decimal{} = d), do: d
  defp to_number(value) when is_number(value), do: value

  defp to_number(value) when is_binary(value) do
    # Match Liquid: a string that is fully `-?\d+\.\d+` parses as a float
    # (BigDecimal in Ruby); otherwise fall back to `String#to_i`, which parses
    # leading digits and yields 0 if none. So `'4.6abc'` -> 4, not 0 or 4.6.
    case Integer.parse(value) do
      {int_val, ""} ->
        int_val

      {int_val, "." <> _rest} ->
        case Float.parse(value) do
          {float_value, ""} -> float_value
          _ -> int_val
        end

      {int_val, _rest} ->
        int_val

      :error ->
        0
    end
  end

  defp to_number(_), do: 0
end
