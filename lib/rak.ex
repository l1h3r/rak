defmodule Rak do
  @moduledoc """
  Documentation for Rak.
  """
  use Application

  alias Rak.{
    Config,
    Job,
    Persistence,
    Queue,
    Stats,
    Supervisor,
    Util,
    Util.Datetime,
    Worker
  }

  @type delay :: {:seconds | :minutes | :hours, integer()}

  def start(_type, _args), do: start_link()
  defdelegate start_link(opts \\ []), to: Supervisor
  defdelegate child_spec(opts), to: Supervisor

  defdelegate i, to: Util.Info, as: :info
  defdelegate c, to: Config, as: :all
  defdelegate c(path, default \\ nil), to: Config, as: :get
  defdelegate subscribe, to: Job.Event
  defdelegate unsubscribe, to: Job.Event
  defdelegate resume(name), to: Queue.Server
  defdelegate suspend(name), to: Queue.Server
  defdelegate stats, to: Stats, as: :data
  defdelegate jobs, to: Persistence, as: :all
  defdelegate jobs(status), to: Persistence, as: :by_status

  defdelegate scheduled_queue, to: Job.Tracker, as: :queue
  defdelegate purge_scheduled, to: Job.Tracker, as: :purge
  defdelegate flush_scheduled, to: Job.Tracker, as: :flush
  defdelegate reload_scheduled, to: Job.Tracker, as: :reload
  defdelegate valid_worker?(module), to: Worker, as: :valid?
  defdelegate validate_worker!(module), to: Worker, as: :validate!

  defdelegate retry(job), to: __MODULE__, as: :run_clean
  defdelegate flush(job), to: __MODULE__, as: :run_clean

  @spec run_clean(job :: Job.t()) :: Job.t()
  def run_clean(%Job{} = job) do
    job
    |> Job.error()
    |> Job.status(:enqueued)
    |> Job.enqueue()
  end

  @doc """
  Enqueue a job to be run in the background.
  """
  @spec enqueue(module :: module(), args :: any(), opts :: keyword()) :: Job.t()
  def enqueue(module, args, opts \\ []) do
    Job.create(module, args, Keyword.merge(opts, status: :enqueued))
  end

  @doc """
  Enqueue a job to be run in the background after a specified delay
  """
  @spec enqueue_at(module(), any(), integer(), keyword()) :: Job.t()
  @spec enqueue_at(module(), any(), delay(), keyword()) :: Job.t()
  def enqueue_in(_, _, _, _ \\ [])

  def enqueue_in(module, args, {:seconds, value}, opts) when is_integer(value),
    do: enqueue_in(module, args, value * 1000, opts)

  def enqueue_in(module, args, {:minutes, value}, opts) when is_integer(value),
    do: enqueue_in(module, args, value * 60 * 1000, opts)

  def enqueue_in(module, args, {:hours, value}, opts) when is_integer(value),
    do: enqueue_in(module, args, value * 60 * 60 * 1000, opts)

  def enqueue_in(module, args, delay, opts) when is_integer(delay) do
    enqueue_at(module, args, Datetime.now() + delay, opts)
  end

  def enqueue_in(_, _, delay, _), do: raise(ArgumentError, "Invalid delay: #{inspect(delay)}")

  @doc """
  Enqueue a job to be run in the background at a specified time
  """
  @spec enqueue_at(module(), any(), integer(), keyword()) :: Job.t()
  @spec enqueue_at(module(), any(), DateTime.t(), keyword()) :: Job.t()
  @spec enqueue_at(module(), any(), NaiveDateTime.t(), keyword()) :: Job.t()
  def enqueue_at(_, _, _, _ \\ [])

  def enqueue_at(module, args, %DateTime{} = datetime, opts),
    do: enqueue_at(module, args, Datetime.to_unix(datetime), opts)

  def enqueue_at(module, args, %NaiveDateTime{} = naive, opts),
    do: enqueue_at(module, args, Datetime.to_unix(naive), opts)

  def enqueue_at(module, args, at, opts) when is_integer(at) do
    Job.create(module, args, Keyword.merge(opts, status: :scheduled, perform_at: at))
  end

  def enqueue_at(_, _, at, _), do: raise(ArgumentError, "Invalid datetime: #{inspect(at)}")
end
