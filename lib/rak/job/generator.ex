defmodule Rak.Job.Generator do
  @moduledoc """
  Rak Job Generator
  """
  use Agent
  alias Rak.Util.Rand

  # ====== #
  # Client #
  # ====== #

  @spec start_link(args :: keyword()) :: GenServer.on_start()
  def start_link(_ \\ []), do: Agent.start_link(&Map.new/0, name: __MODULE__)

  @doc """
  Generates a unique key, saving and returning the value
  """
  @spec generate :: String.t()
  def generate, do: Agent.get_and_update(__MODULE__, &Rand.unique/1)

  @doc """
  Returns a list of all generated keys
  """
  @spec keys :: list(String.t())
  def keys, do: Agent.get(__MODULE__, &Map.keys/1)
end
