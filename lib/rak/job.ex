defmodule Rak.Job do
  @moduledoc """
  Rak Job
  """
  use Rak.Util.Logger

  alias Rak.{
    Config,
    Job,
    Job.Generator,
    Job.Runner,
    Job.Tracker,
    Persistence,
    Util.Datetime,
    Util.Unsafe,
    Worker
  }

  @timeout Config.get(:timeout)

  @queues Config.get(:queues)

  @default_queue Config.get(:default_queue)

  @version 1

  @statuses [:created, :enqueued, :failed, :scheduled]

  defstruct id: nil,
            module: nil,
            error: "",
            args: [],
            status: :created,
            queue: @default_queue,
            perform_at: :undefined,
            version: @version

  @type t :: %Job{
          id: jid() | nil,
          module: module() | nil,
          error: String.t() | nil,
          args: list(),
          status: atom(),
          queue: atom(),
          perform_at: integer() | atom(),
          version: integer()
        }

  @type jid :: String.t()

  @type status :: :created | :enqueued | :failed | :scheduled

  @type concurrency :: non_neg_integer() | :infinite

  @type executed :: {:ok, t} | {:error, t, String.t(), list()}

  @doc """
  Returns a list of all job attributes.
  """
  @spec keys :: list(atom())
  def keys, do: %Job{} |> Map.from_struct() |> Map.keys() |> Enum.sort()

  @doc """
  Returns a list of all job statuses.
  """
  @spec statuses :: list(atom())
  def statuses, do: @statuses

  @doc """
  Creates a new job struct from an existing one. See `new/3`.
  """
  @spec new(job :: t) :: t
  def new(%Job{module: module, args: args}), do: new(module, args)

  @doc """
  Creates and validates a new job struct.

  ## Examples

      iex> new(RakTest.Worker, [])
      %Job{module: RakTest.Worker, status: :created}

      iex> new(RakTest.NotAWorker, [])
      ** (Rak.Error.WorkerError) Elixir.RakTest.NotAWorker is not a valid worker

      iex> new(%Job{module: RakTest.Worker, args: [:hey]})
      %Job{module: RakTest.Worker, args: [:hey]}

  """
  @spec new(module :: module, args :: any()) :: t
  def new(module, args) do
    :ok = Worker.validate!(module)

    struct!(Job, %{module: module, args: args})
  end

  @doc """
  Creates and enqueues a new job.

  ## Examples

      iex> create(RakTest.Worker, []) |> Map.get(:status)
      :created

      iex> RakTest.Worker |> create([], status: :scheduled) |> Map.get(:status)
      :scheduled

      iex> create(RakTest.Worker, [], status: :banana)
      ** (ArgumentError) Invalid value for job `status`: :banana

      iex> at = :os.system_time(:milli_seconds) + 50
      iex> RakTest.Worker |> create([], perform_at: at) |> expired?()
      false

  """
  @spec create(module :: module, args :: any(), opts :: keyword()) :: t
  def create(module, args, opts \\ []) do
    module
    |> Job.new(args)
    |> attr_if_exists(:perform_at, opts)
    |> attr_if_exists(:status, opts)
    |> attr_if_exists(:queue, opts)
    |> Job.enqueue()
  end

  @doc """
  Persists and enqueues a job.

  ## Examples

      iex> job = Job.new(RakTest.Worker, [])
      iex> job |> Map.get(:id) |> is_nil()
      true
      iex> job = enqueue(job)
      iex> job |> Map.get(:id) |> is_nil()
      false
      iex> Map.get(job, :status)
      :created
      iex> job = job |> status(:scheduled) |> enqueue()
      iex> Map.get(job, :status)
      :scheduled

  """
  @spec enqueue(job :: t) :: t
  def enqueue(%Job{} = job) do
    job
    |> persist()
    |> register()
  end

  @doc """
  Executes a job as a spawned process.
  """
  @spec execute(job :: t) :: executed()
  def execute(%Job{module: module, args: args} = job) do
    :ok = log(:debug, job, "Running")

    case Unsafe.run({module, :perform, [args]}, @timeout) do
      :ok ->
        {:ok, job}

      {:error, reason, stack} ->
        {:error, job, reason, stack}
    end
  end

  @doc """
  Checks if the given status is valid.

  ## Examples

      iex> status?(:failed)
      true

      iex> status?(:banana)
      false

  """
  @spec status?(status :: atom()) :: boolean()
  def status?(status), do: status in @statuses

  @doc """
  Checks if the given job is valid.

  ## Examples

      iex> valid?(%Job{module: RakTest.Worker})
      true

      iex> valid?(%Job{module: RakTest.NotWorker})
      false

  """
  @spec valid?(job :: t) :: boolean()
  def valid?(%Job{module: module}), do: Worker.valid?(module)

  @doc """
  Checks if the given job is ready to perform.

  ## Examples

      iex> expired?(%Job{})
      true

      iex> expired?(%Job{perform_at: :os.system_time(:milli_seconds) + 5000})
      false

  """
  @spec expired?(job :: t) :: boolean()
  def expired?(%Job{perform_at: :undefined}), do: true
  def expired?(%Job{perform_at: perform_at}), do: perform_at <= Datetime.now()

  @doc """
  Checks if the given job has an error.

  ## Examples

      iex> error?(%Job{error: "failed"})
      true

      iex> error?(%Job{})
      false

  """
  @spec error?(job :: t) :: boolean()
  def error?(%Job{error: nil}), do: false
  def error?(%Job{error: ""}), do: false
  def error?(_), do: true

  @doc """
  Returns the concurrency value for the given job.
  """
  @spec concurrency(job :: Job.t()) :: concurrency()
  def concurrency(%Job{module: module}) do
    with :ok <- Worker.validate!(module), do: module.concurrency()
  end

  @doc """
  Sets job `error` to the given `reason` or clears the job error.

  ## Examples

      iex> error(%Job{error: "something"})
      %Job{error: nil}

      iex> error(%Job{}, "failed")
      %Job{error: "failed"}

      iex> error(%Job{}, ["failed", "more failed"])
      ** (ArgumentError) Invalid value for job `error`: ["failed", "more failed"]

  """
  @spec error(job :: t, reason :: String.t() | nil) :: t
  def error(_, _ \\ nil)

  def error(%Job{} = job, reason) when is_binary(reason) or is_nil(reason),
    do: %Job{job | error: reason}

  def error(_, reason), do: raise_attr_error(:error, reason)

  @doc """
  Sets job `status` to the given `status`

  ## Examples

      iex> status(%Job{status: :enqueued}, :failed)
      %Job{status: :failed}

      iex> status(%Job{status: :failed}, :scheduled)
      %Job{status: :scheduled}

      iex> status(%Job{status: :failed}, [:hello])
      ** (ArgumentError) Invalid value for job `status`: [:hello]

  """
  @spec status(job :: t, status :: atom()) :: t
  def status(%Job{} = job, status) when status in @statuses, do: %Job{job | status: status}
  def status(_, status), do: raise_attr_error(:status, status)

  @doc """
  Sets job `queue` to the given `queue`

  ## Examples

      iex> queue(%Job{queue: :default}, :immediate)
      %Job{queue: :immediate}

      iex> queue(%Job{queue: :default}, %{name: :default})
      ** (ArgumentError) Invalid value for job `queue`: %{name: :default}

  """
  @spec queue(job :: t, queue :: atom()) :: t
  def queue(%Job{} = job, queue) when queue in @queues, do: %Job{job | queue: queue}
  def queue(_, queue), do: raise_attr_error(:queue, queue)

  @doc """
  Sets job `id` to the given `id`. See `id/2`.
  """
  @spec id(job :: t) :: t
  def id(%Job{} = job), do: id(job, Generator.generate())

  @doc """
  Sets job `id` to the given `id`

  ## Examples

      iex> id(%Job{id: nil}, "job-123")
      %Job{id: "job-123"}

      iex> id(%Job{id: nil}, ["hello", "world"])
      ** (ArgumentError) Invalid value for job `id`: ["hello", "world"]

  """
  @spec id(job :: t, id :: String.t()) :: t
  def id(%Job{} = job, id) when is_binary(id), do: %Job{job | id: id}
  def id(_, id), do: raise_attr_error(:id, id)

  @doc """
  Sets job `perform_at` from the given `delay` or to the given `datetime`.

  ## Examples

      iex> perform_at(%Job{}, 5000)
      %Job{perform_at: 5000}

      iex> perform_at(%Job{}, %{delay: 10000})
      ** (ArgumentError) Invalid value for job `perform_at`: %{delay: 10000}

  """
  @spec perform_at(job :: t, at :: integer()) :: t
  def perform_at(%Job{} = job, at) when is_integer(at), do: %Job{job | perform_at: at}
  def perform_at(_, at), do: raise_attr_error(:perform_at, at)

  # ======= #
  # Private #
  # ======= #

  @spec attr_if_exists(job :: t, key :: atom(), opts :: keyword()) :: t
  defp attr_if_exists(job, key, opts) do
    if attr = Keyword.get(opts, key) do
      apply(__MODULE__, key, [job, attr])
    else
      job
    end
  end

  @spec raise_attr_error(key :: atom(), value :: any()) :: no_return()
  defp raise_attr_error(key, value) do
    raise(ArgumentError, "Invalid value for job `#{key}`: #{inspect(value)}")
  end

  @spec register(job :: t) :: t
  defp register(job) do
    if expired?(job) do
      Runner.register(job)
    else
      Tracker.register(job)
    end
  end

  @spec persist(job :: t) :: t
  defp persist(%Job{id: nil} = job), do: job |> id() |> Persistence.insert()
  defp persist(%Job{} = job), do: Persistence.update(job)
end
