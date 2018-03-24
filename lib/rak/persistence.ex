defmodule Rak.Persistence do
  @moduledoc """
  Rak Persistence

  Defines the specification for a job persistence module
  """
  alias Rak.{
    Config,
    Job
  }

  @doc """
  Starts a supervised job persistence process.
  """
  @callback start_link(opts :: keyword()) :: Supervisor.on_start()

  @doc """
  The supervisor child spec.
  """
  @callback child_spec(opts :: keyword()) :: Supervisor.child_spec()

  @doc """
  Returns a list of all jobs.
  """
  @callback all :: list(Job.t())

  @doc """
  Finds a job by the given job id or returns nil.
  """
  @callback find(jid :: Job.jid()) :: Job.t() | nil

  @doc """
  Returns a list of all jobs with the given status.
  """
  @callback by_status(status :: Job.status()) :: list(Job.t())

  @doc """
  Destroys the job with the given jod id.
  """
  @callback destroy(jid :: Job.jid()) :: :ok | no_return()

  @doc """
  Inserts a new job struct.
  """
  @callback insert(job :: Job.t()) :: Job.t() | no_return()

  @doc """
  Updates an existing job struct with new attributes.
  """
  @callback update(job :: Job.t()) :: Job.t() | no_return()

  @doc """
  Clears all persisted jobs
  """
  @callback clear :: :ok | no_return()

  defmacro __using__(_) do
    quote do
      alias Rak.{
        Job,
        Persistence
      }

      @behaviour Persistence

      @impl true
      def start_link(_), do: :ignore

      @impl true
      def child_spec(_), do: %{id: __MODULE__, start: {__MODULE__, :start_link, []}}

      @impl true
      def all, do: []

      @impl true
      def find(jid), do: nil

      @impl true
      def by_status(status), do: []

      @impl true
      def destroy(jid), do: :ok

      @impl true
      def insert(job), do: job

      @impl true
      def update(job), do: job

      @impl true
      def clear, do: :ok

      defoverridable Persistence
    end
  end

  @adapter Config.get(:storage_adapter)

  @spec adapter :: module()
  def adapter, do: @adapter

  defdelegate start_link(opts \\ []), to: @adapter
  defdelegate child_spec(opts \\ []), to: @adapter
  defdelegate all, to: @adapter
  defdelegate find(jid), to: @adapter
  defdelegate by_status(status), to: @adapter
  defdelegate destroy(jid), to: @adapter
  defdelegate insert(job), to: @adapter
  defdelegate update(job), to: @adapter
  defdelegate clear, to: @adapter
end
