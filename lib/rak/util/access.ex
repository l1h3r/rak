defmodule Rak.Util.Access do
  @moduledoc """
  Rak Util Access
  """

  @doc """
  Gets a value from a nested structure or returns the default.

  ## Examples

      iex> Access.get(%{key: %{nested: "hello"}}, [:key, :nested])
      "hello"

      iex> Access.get([key: [nested: "world"]], [:key, :nested])
      "world"

      iex> Access.get(%{key: %{nested: "hello"}}, ["key", :nested])
      nil

      iex> Access.get(%{key: %{nested: "hello"}}, ["key", :nested], "world")
      "world"

      iex> Access.get([], :noexist, fn -> "hello world" end)
      "hello world"

  """
  @spec get(data :: term(), key :: atom(), default :: any()) :: any()
  @spec get(data :: term(), path :: list(), default :: any()) :: any()
  def get(_, _, _ \\ nil)
  def get(data, key, default) when is_atom(key), do: get(data, [key], default)

  def get(data, path, default) when is_list(path) and is_function(default) do
    data |> get_in(path) |> Kernel.||(default.())
  end

  def get(data, path, default) when is_list(path), do: get(data, path, fn -> default end)

  @doc """
  Deep merges two keyword lists.

  ## Examples

      iex> Access.merge([key: [nested: :v1, nested2: :v1]], [key: [nested: :v2]])
      [key: [nested2: :v1, nested: :v2]]

      iex> Access.merge([key: [nested: :v1]], [key: []])
      [key: [nested: :v1]]

  """
  @spec merge(data1 :: keyword(), data2 :: keyword()) :: list()
  def merge(data1, data2) when is_list(data1) and is_list(data2),
    do: deep_merge(nil, data1, data2)

  @spec deep_merge(key :: atom(), v2 :: any(), v2 :: any()) :: any()
  defp deep_merge(_, v1, v2) do
    if Keyword.keyword?(v1) and Keyword.keyword?(v2) do
      Keyword.merge(v1, v2, &deep_merge/3)
    else
      v2 || v1
    end
  end
end
