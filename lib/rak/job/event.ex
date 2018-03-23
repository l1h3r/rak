defmodule Rak.Job.Event do
  @moduledoc """
  Rak Job Event

  Handles job event pub/sub and event broadcasting
  """
  use GenServer
  alias Rak.Job

  @type event :: {:completed | :failed, Job.t()}

  # ====== #
  # Client #
  # ====== #

  @spec start_link(args :: keyword()) :: GenServer.on_start()
  def start_link(_ \\ []), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @doc """
  Subscribes the current process to Job events.

  Events are sent as messages to the current process.
  """
  @spec subscribe :: :ok
  def subscribe, do: GenServer.call(__MODULE__, :subscribe)

  @doc """
  Unsubscribes the current process.
  """
  @spec unsubscribe :: :ok
  def unsubscribe, do: GenServer.call(__MODULE__, :unsubscribe)

  @doc """
  Notifies all listeners of a Job event.
  """
  @spec notify(event :: event()) :: :ok
  def notify({key, %Job{}} = event) when is_atom(key) do
    GenServer.cast(__MODULE__, {:notify, event})
  end

  # ====== #
  # Server #
  # ====== #

  def init(:ok), do: {:ok, []}

  def handle_call(:subscribe, {pid, _}, listeners), do: {:reply, :ok, [pid | listeners]}

  def handle_call(:unsubscribe, {pid, _}, listeners), do: {:reply, :ok, listeners -- [pid]}

  def handle_cast({:notify, event}, listeners) do
    :ok = Enum.each(listeners, &send(&1, event))

    {:noreply, listeners}
  end
end
