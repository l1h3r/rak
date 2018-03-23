defmodule Rak.Job.Runner do
  @moduledoc """
  Rak Job Runner
  """
  use GenServer
  use Rak.Util.Logger

  alias Rak.{
    Job,
    Job.Event,
    Persistence,
    Retry,
    Worker
  }

  alias Rak.Queue.Server, as: Queue

  @type error :: {:error, Job.t(), String.t(), list()} | {:error, Job.t()}
  @type result :: {:ok, Job.t()} | error()

  # ====== #
  # Client #
  # ====== #

  @spec start_link(args :: keyword()) :: GenServer.on_start()
  def start_link(_ \\ []), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @spec register(job :: Job.t()) :: Job.t()
  def register(%Job{module: module} = job) do
    with :ok <- Worker.validate!(module),
         :ok <- GenServer.cast(__MODULE__, {:register, job}) do
      job
    end
  end

  @spec run_job(job :: Job.t()) :: result()
  def run_job(%Job{} = job) do
    job
    |> Queue.push()
    |> retry()
    |> process()
  end

  # ====== #
  # Server #
  # ====== #

  def init(:ok) do
    {:ok, []}
  end

  def handle_cast({:register, job}, state) do
    :ok = log(:debug, job, "Spawning")

    spawn_link(__MODULE__, :run_job, [job])

    {:noreply, state}
  end

  # ======= #
  # Private #
  # ======= #

  @spec retry(result :: result(), attempt :: integer()) :: result()
  defp retry(_, _ \\ 1)
  defp retry({:ok, _} = result, _), do: result

  defp retry({:error, job, _, _} = error, attempt) do
    if Retry.retry?(job, attempt) do
      perform_retry(job, attempt)
    else
      error
    end
  end

  defp perform_retry(job, attempt) do
    :ok = log(:debug, job, "Retry(W) ##{attempt}")
    :ok = Event.notify({:retry, job})
    :ok = Retry.wait(attempt)
    :ok = log(:debug, job, "Retry(P) ##{attempt}")

    job
    |> Queue.push()
    |> retry(attempt + 1)
  end

  @spec process(result :: result()) :: result()
  defp process({:ok, %{id: id, module: module} = job}) do
    :ok = Persistence.destroy(id)
    :ok = module.on_completed(job)
    :ok = Event.notify({:completed, job})

    {:ok, job}
  end

  defp process({:error, %{module: module} = job, reason, stack}) do
    job =
      job
      |> Job.error(reason)
      |> Job.status(:failed)
      |> Persistence.update()

    :ok = module.on_failed(job, reason, stack)
    :ok = Event.notify({:failed, job})

    {:error, job}
  end
end
