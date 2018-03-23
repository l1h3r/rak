defmodule Rak.Util.Datetime do
  @moduledoc """
  Rak Util Datetime
  """

  @doc """
  Converts the datetime or naive datetime to unix time.

  ## Examples

      iex> datetime = "2018-03-20T00:00:00Z" |> DateTime.from_iso8601() |> elem(1)
      iex> Datetime.to_unix(datetime)
      1521504000000

      iex> datetime = "2018-03-20T00:00:00" |> NaiveDateTime.from_iso8601!()
      iex> Datetime.to_unix(datetime)
      1521504000000

  """
  @spec to_unix(datetime :: DateTime.t() | NaiveDateTime.t()) :: integer()
  def to_unix(%DateTime{} = datetime), do: DateTime.to_unix(datetime, :millisecond)

  def to_unix(%NaiveDateTime{} = naive), do: naive |> DateTime.from_naive!("Etc/UTC") |> to_unix()

  @doc """
  Returns the current UTC datetime in unix time.
  """
  @spec now :: integer()
  def now, do: DateTime.utc_now() |> to_unix()
end
