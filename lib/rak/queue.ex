defmodule Rak.Queue do
  @moduledoc """
  Rak Queue
  """
  use Rak.Util.Accessor

  alias Rak.{
    Config,
    Job,
    Queue
  }

  defstruct name: :default,
            pending: :queue.new(),
            running: 0,
            status: :idle

  @type t :: %Queue{
          name: atom(),
          pending: :queue.queue(),
          running: non_neg_integer(),
          status: atom()
        }

  @type item :: {Job.t(), pid()}

  @statuses [:idle, :active, :suspended]

  @doc """
  Returns a list of all queue statuses.
  """
  @spec statuses :: list(atom())
  def statuses, do: @statuses

  @doc """
  Returns a list of all available queue names.
  """
  @spec names :: list(atom())
  def names, do: :queues |> Config.get() |> Enum.uniq()

  @doc """
  Returns info about the given queue.

  ## Example

      iex> queue = new(:test)
      iex> queue = push(queue, {%Rak.Job{}, self()})
      iex> queue = push(queue, {%Rak.Job{}, self()})
      iex> queue = push(queue, {%Rak.Job{}, self()})
      iex> info(queue)
      [name: :test, status: :idle, running: 0, pending: 3]

  """
  @spec info(queue :: t) :: keyword()
  def info(%Queue{name: name, status: status, running: running, pending: pending}) do
    [
      name: name,
      status: status,
      running: running,
      pending: :queue.len(pending)
    ]
  end

  @doc """
  Creates a new queue struct with the given name.

  ## Examples

      iex> new(:test)
      %Queue{name: :test}

      iex> new([:queue1, :queue2])
      ** (ArgumentError) Expected queue name to be an atom. got: [:queue1, :queue2]

  """
  @spec new(name :: atom()) :: t
  def new(name) when is_atom(name), do: %Queue{name: name}

  def new(name),
    do: raise(ArgumentError, "Expected queue name to be an atom. got: #{inspect(name)}")

  @doc """
  Checks if the given status is valid.

  ## Examples

      iex> status?(:suspended)
      true

      iex> status?(:banana)
      false

  """
  enum(:status?, @statuses)

  @doc """
  Sets queue `status` to the given `status`

  ## Examples

      iex> status(%Queue{status: :idle}, :suspended)
      %Queue{status: :suspended}

      iex> status(%Queue{status: :idle}, :banana)
      ** (ArgumentError) Invalid value for `status`: :banana

  """
  accessor(:status, :atom, @statuses)

  @doc """
  Checks if the job can be performed in the queue.

  ## Examples

      iex> allowed?(%Queue{status: :suspended}, %Job{})
      false

      iex> allowed?(%Queue{status: :idle}, %Job{module: RakTest.Worker})
      true

  """
  @spec allowed?(queue :: t, job :: Job.t()) :: boolean()
  def allowed?(%Queue{status: :suspended}, %Job{}), do: false

  def allowed?(%Queue{running: running}, %Job{} = job) do
    case Job.concurrency(job) do
      :infinite -> true
      int when is_integer(int) -> running < int
    end
  end

  @doc """
  Pushes a new job to the end of the queue.

  ## Example

      iex> queue = new(:test)
      iex> queue = push(queue, {%Rak.Job{args: :job1}, self()})
      iex> queue = push(queue, {%Rak.Job{args: :job2}, self()})
      iex> pop(queue) |> elem(0)
      {%Rak.Job{args: :job1}, self()}

  """
  @spec push(queue :: t, item :: item()) :: t
  def push(%Queue{pending: pending} = queue, {%Job{} = job, caller}) do
    %Queue{queue | pending: :queue.in({job, caller}, pending)}
  end

  @doc """
  Removes the first job at the front of the queue.

  ## Example

      iex> queue = new(:test)
      iex> queue = push(queue, {%Rak.Job{args: :job1}, self()})
      iex> queue = push(queue, {%Rak.Job{args: :job2}, self()})
      iex> {item, queue} = pop(queue)
      iex> item
      {%Rak.Job{args: :job1}, self()}
      iex> pop(queue) |> elem(0)
      {%Rak.Job{args: :job2}, self()}

  """
  @spec pop(queue :: t) :: {item(), t} | t
  def pop(%Queue{pending: pending} = queue) do
    case :queue.out(pending) do
      {:empty, _} -> queue
      {{:value, item}, pending} -> {item, %Queue{queue | pending: pending}}
    end
  end

  @doc """
  Increments the running job count by 1.

  ## Example

      iex> queue = new(:test)
      iex> queue = incr(queue)
      iex> queue = incr(queue)
      iex> incr(queue)
      %Queue{name: :test, running: 3}

  """
  @spec incr(queue :: t) :: t
  def incr(%Queue{running: running} = queue), do: %Queue{queue | running: running + 1}

  @doc """
  Decrements the running job count by 1.

  ## Example

      iex> queue = new(:test)
      iex> queue = incr(queue)
      iex> queue = incr(queue)
      %Queue{name: :test, running: 2}
      iex> queue = decr(queue)
      %Queue{name: :test, running: 1}
      iex> queue = decr(queue)
      %Queue{name: :test, running: 0}
      iex> decr(queue)
      %Queue{name: :test, running: 0}

  """
  @spec decr(queue :: t) :: t
  def decr(%Queue{running: running} = queue), do: %Queue{queue | running: max(0, running - 1)}
end
