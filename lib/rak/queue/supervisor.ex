defmodule Rak.Queue.Supervisor do
  @moduledoc """
  Rak Queue Supervisor
  """
  use Supervisor

  alias Rak.{
    Queue,
    Queue.Server
  }

  @opts [
    strategy: :one_for_one,
    name: __MODULE__
  ]

  # ====== #
  # Client #
  # ====== #

  @spec start_link(opts :: keyword()) :: Supervisor.on_start()
  def start_link(_ \\ []), do: Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  @spec child_spec(opts :: keyword()) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      type: :supervisor,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  # ====== #
  # Server #
  # ====== #

  def init(:ok) do
    Queue.names()
    |> Enum.map(&{Server, &1})
    |> Supervisor.init(@opts)
  end
end
