defmodule Rak.Supervisor do
  @moduledoc """
  Rak Supervisor
  """
  use Supervisor

  alias Rak.{
    Persistence,
    Stats
  }

  alias Rak.Job.Supervisor, as: JobSupervisor
  alias Rak.Queue.Supervisor, as: QueueSupervisor

  @children [
    Persistence,
    JobSupervisor,
    QueueSupervisor,
    Stats
  ]

  @opts [
    strategy: :one_for_all,
    name: Rak.Supervisor,
    max_seconds: 20,
    max_restarts: 5
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

  def init(:ok), do: Supervisor.init(@children, @opts)
end
