defmodule Rak.Util.Rand do
  @moduledoc """
  Rak Util Rand

  Random value generation
  """
  @keysize 16

  @doc """
  Generates a random base16-encoded string.
  """
  @spec generate(bytes :: integer()) :: String.t()
  def generate(bytes \\ @keysize),
    do: bytes |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower)

  @doc """
  Generates a random string, ensuring it is unique to the given map.
  """
  @spec unique(map :: map()) :: {String.t(), map()}
  @spec unique({map :: map(), id :: String.t()}) :: {String.t(), map()}
  @spec unique({map :: map(), id :: String.t(), exists :: boolean()}) :: {String.t(), map()}
  def unique(map) when is_map(map), do: unique({map, generate()})
  def unique({map, id}), do: unique({map, id, Map.has_key?(map, id)})
  def unique({map, _, true}), do: unique({map, generate()})
  def unique({map, id, _}), do: {id, Map.put(map, id, true)}
end
