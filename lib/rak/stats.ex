defmodule Rak.Stats do
  @moduledoc """
  Rak Stats

  Handles job stat tracking. TODO: Re-work into something less terrible
  """
  use GenServer

  alias Rak.{
    Config,
    Job.Event,
    Persistence
  }

  @table Config.get(:stats_table)

  @table_opts [
    {:read_concurrency, true},
    :public,
    :named_table
  ]

  @counters [:completed, :retries, :failed]

  # ====== #
  # Client #
  # ====== #

  @spec start_link(opts :: keyword()) :: GenServer.on_start()
  def start_link(_ \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec data :: map()
  def data, do: GenServer.call(__MODULE__, :data)

  # ====== #
  # Server #
  # ====== #

  def init(:ok) do
    @table = :ets.new(@table, @table_opts)

    :ok = Event.subscribe()

    {:ok, []}
  end

  def handle_call(:data, _, state), do: {:reply, stats(), state}

  def handle_info({:completed, _}, state), do: increment(:completed, state)

  def handle_info({:retry, _}, state), do: increment(:retries, state)

  def handle_info({:failed, _}, state), do: increment(:failed, state)

  # ======= #
  # Private #
  # ======= #

  @spec increment(key :: atom(), state :: list()) :: {:noreply, list()}
  defp increment(key, state) when key in @counters do
    case :ets.update_counter(@table, key, 1, {key, 0}) do
      int when is_integer(int) -> :ok
      _ -> :error
    end

    {:noreply, state}
  end

  @spec stats :: map()
  defp stats do
    jobs = Persistence.all()
    data = @table |> :ets.tab2list() |> Enum.into(%{})

    @counters
    |> Enum.map(&{&1, 0})
    |> Enum.into(%{})
    |> Map.merge(data)
    |> Map.put(:enqueued, count_status(jobs, :enqueued))
    |> Map.put(:scheduled, count_status(jobs, :scheduled))
  end

  @spec count_status(data :: keyword(), status :: atom()) :: integer()
  defp count_status(data, status), do: Enum.count(data, &match?(%{status: ^status}, &1))
end
