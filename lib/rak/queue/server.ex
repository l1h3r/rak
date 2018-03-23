defmodule Rak.Queue.Server do
  @moduledoc """
  Rak Queue Server
  """
  use GenServer

  alias Rak.{
    Job,
    Queue
  }

  @type item :: Queue.item()
  @type name :: atom() | pid()

  # ====== #
  # Client #
  # ====== #

  @spec start_link(name :: atom()) :: GenServer.on_start()
  def start_link(name), do: GenServer.start_link(__MODULE__, name, name: via(name))

  @spec child_spec(name :: atom()) :: Supervisor.child_spec()
  def child_spec(name) do
    %{
      id: via(name),
      start: {__MODULE__, :start_link, [name]}
    }
  end

  @doc """
  Pushes a job to the queue and blocks until a response is received.
  """
  @spec push(job :: Job.t()) :: Job.executed()
  def push(%Job{queue: queue} = job) do
    with :ok <- request(queue, job), do: wait(queue)
  end

  @doc """
  Request a job execution from the queue.
  """
  @spec request(name :: name(), job :: Job.t()) :: :ok
  def request(name, %Job{} = job), do: name |> via() |> GenServer.cast({:request, job, self()})

  @doc """
  Confirm a queued job execution.
  """
  @spec confirm(name :: name(), job :: Job.t()) :: :ok
  def confirm(name, %Job{} = job), do: name |> via() |> GenServer.cast({:confirm, job})

  @doc """
  Gets the current state of the queue server.
  """
  @spec status(name :: name()) :: keyword()
  def status(name), do: name |> via() |> GenServer.call(:status)

  # ====== #
  # Server #
  # ====== #

  def init(name), do: {:ok, Queue.new(name)}

  def handle_call(:status, _, queue), do: {:reply, Queue.info(queue), queue}

  def handle_cast({:request, job, pid}, queue), do: {:noreply, now_or(queue, {job, pid})}

  def handle_cast({:confirm, job}, queue), do: {:noreply, queue |> Queue.decr() |> next_or(job)}

  # ======= #
  # Private #
  # ======= #

  @spec wait(name :: atom()) :: no_return()
  defp wait(name) do
    receive do
      {:run, job} ->
        result = Job.execute(job)
        :ok = confirm(name, job)
        result
    end
  end

  @spec run_now(queue :: Queue.t(), {job :: Job.t(), caller :: pid()}) :: Queue.t()
  defp run_now(queue, {job, caller}) do
    send(caller, {:run, job})
    Queue.incr(queue)
  end

  @spec run_next(queue :: Queue.t()) :: Queue.t()
  defp run_next(queue) do
    queue
    |> Queue.pop()
    |> case do
      {{job, caller}, queue} -> run_now(queue, {job, caller})
      _ -> queue
    end
  end

  @spec now_or(queue :: Queue.t(), item :: item()) :: Queue.t()
  defp now_or(queue, {job, caller}) do
    if Queue.allowed?(queue, job) do
      run_now(queue, {job, caller})
    else
      Queue.push(queue, {job, caller})
    end
  end

  @spec next_or(queue :: Queue.t(), job :: Job.t()) :: Queue.t()
  defp next_or(%Queue{} = queue, job) do
    if Queue.allowed?(queue, job) do
      run_next(queue)
    else
      queue
    end
  end

  @spec via(name :: name()) :: pid() | {:via, {module(), atom()}}
  defp via(pid) when is_pid(pid), do: pid
  defp via(name), do: {:global, {__MODULE__, :"rak_queue_#{name}"}}
end
