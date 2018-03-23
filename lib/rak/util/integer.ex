defmodule Rak.Util.Integer do
  @moduledoc """
  Rak Util Integer
  """

  @doc """
  Parses the value as an integer or returns the default.

  ## Examples

      iex> Integer.safe_parse("12312")
      12312

      iex> Integer.safe_parse("sdfgkjsdfgd", 5000)
      5000

      iex> Integer.safe_parse("12312fsfssdf", 400)
      12312

  """
  @spec safe_parse(num :: any(), default :: integer()) :: integer()
  def safe_parse(_, _ \\ 0)
  def safe_parse(nil, default), do: default
  def safe_parse(num, _) when is_integer(num), do: num
  def safe_parse(num, default) when is_atom(num), do: num |> to_string() |> safe_parse(default)
  def safe_parse(num, default) when is_binary(num), do: num |> Integer.parse() |> extract(default)

  @spec extract({int :: integer(), remainder :: String.t()}, default :: integer()) :: integer()
  @spec extract(:error, default :: integer()) :: integer()
  defp extract({int, _}, _), do: int
  defp extract(:error, default), do: default
end
