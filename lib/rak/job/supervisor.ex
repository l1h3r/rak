defmodule Rak.Job.Supervisor do
  @moduledoc """
  Rak Job Supervisor
  """
  use Supervisor

  alias Rak.Job.{
    Runner,
    Tracker,
    Event,
    Generator
  }

  @children [
    Runner,
    Tracker,
    Event,
    Generator
  ]

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

  def init(:ok), do: Supervisor.init(@children, @opts)
end
