defmodule Rak.Job.Tracker do
  @moduledoc """
  Rak Job Tracker

  Handles tracking of scheduled jobs
  """
  use GenServer
  use Rak.Util.Logger

  alias Rak.{
    Config,
    Job,
    Persistence
  }

  @type jobs :: list(Job.t())
  @type queue :: :queue.queue()

  @flush_interval Config.get_int(:flush_interval)

  # ====== #
  # Client #
  # ====== #

  @spec start_link(args :: keyword()) :: GenServer.on_start()
  def start_link(_ \\ []), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @doc """
  Registers a tracked job.
  """
  @spec register(job :: Job.t()) :: Job.t()
  def register(%Job{} = job) do
    :ok = GenServer.cast(__MODULE__, {:register, job})
    job
  end

  @doc """
  Returns a list of all tracked jobs.
  """
  @spec queue :: list(Job.t())
  def queue, do: GenServer.call(__MODULE__, :queue)

  @doc """
  Flushes all tracked jobs.
  """
  @spec purge :: :ok
  def purge, do: GenServer.cast(__MODULE__, :purge)

  @doc """
  Flushes all expired tracked jobs.
  """
  @spec flush :: :ok
  def flush, do: GenServer.cast(__MODULE__, :flush)

  @doc """
  Reloads the list of tracked jobs.
  """
  @spec reload :: :ok
  def reload, do: GenServer.cast(__MODULE__, :reload)

  # ====== #
  # Server #
  # ====== #

  def init(:ok) do
    schedule()

    {:ok, load_jobs()}
  end

  def handle_call(:queue, _, queue), do: {:reply, :queue.to_list(queue), queue}

  def handle_cast(:reload, _), do: {:noreply, load_jobs()}

  def handle_cast({:register, job}, queue), do: {:noreply, :queue.in(job, queue)}

  def handle_cast(:flush, queue), do: {:noreply, flush_expired_jobs(queue)}

  def handle_cast(:purge, queue), do: {:noreply, flush_jobs(queue)}

  def handle_info(:expire, queue) do
    schedule()
    handle_cast(:flush, queue)
  end

  # ======= #
  # Private #
  # ======= #

  @spec flush_jobs(queue :: queue()) :: queue()
  defp flush_jobs(queue), do: flush_conditional(queue)

  @spec flush_expired_jobs(queue :: queue()) :: queue()
  defp flush_expired_jobs(queue), do: flush_conditional(queue, &Job.expired?/1)

  @spec flush_conditional(queue :: queue(), condition :: fun()) :: queue()
  defp flush_conditional(queue, condition \\ & &1) do
    queue
    |> :queue.to_list()
    |> Enum.reduce(:queue.new(), fn job, acc ->
      if condition.(job) do
        :ok = log(:debug, job, "Flushing")

        %Job{} = Rak.flush_job(job)

        acc
      else
        :queue.in(job, acc)
      end
    end)
  end

  @spec load_jobs :: queue()
  defp load_jobs, do: :scheduled |> Persistence.by_status() |> :queue.from_list()

  @spec schedule :: reference()
  defp schedule, do: Process.send_after(self(), :expire, @flush_interval)
end
