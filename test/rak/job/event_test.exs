defmodule Rak.Job.EventTest do
  use RakTest.Case

  alias Rak.{
    Job,
    Job.Event
  }

  defmodule Listener do
    use GenServer

    def start_link(_ \\ []) do
      GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
    end

    def init(:ok) do
      Process.flag(:trap_exit, true)

      with :ok <- Event.subscribe(), do: {:ok, 0}
    end

    def handle_call(:state, _, state), do: {:reply, state, state}

    def handle_info({:event, %Job{}}, state), do: {:noreply, state + 1}
    def handle_info(_, state), do: {:noreply, state}

    def terminate(_, state) do
      with :ok <- Event.unsubscribe(), do: state
    end
  end

  setup_all do
    {:ok, _} = ensure_supervised(Event)
    :ok
  end

  test "notify/1 sends events to listeners" do
    pid = start_supervised!(Listener)

    state1 = GenServer.call(pid, :state)
    assert state1 == 0

    Enum.each(1..5, fn _ ->
      assert :ok = Event.notify({:event, Job.new(RakTest.Worker, [])})
    end)

    assert :ok = :timer.sleep(5)
    state2 = GenServer.call(pid, :state)
    assert state2 == 5

    :ok = stop_supervised(Listener)
  end
end
