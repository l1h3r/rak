defmodule Rak.StatsTest do
  use RakTest.Case

  alias Rak.{
    Job.Event,
    Persistence,
    Stats
  }

  setup_all do
    {:ok, _} = ensure_supervised(Persistence)
    {:ok, _} = ensure_supervised(Event)
    {:ok, _} = ensure_supervised(Stats)
    :ok
  end

  test "increments on job completed events" do
    assert Stats.data() |> Map.get(:completed) == 0
    assert :ok = Event.notify({:completed, %Rak.Job{}})
    assert :ok = Event.notify({:completed, %Rak.Job{}})
    assert :ok = Event.notify({:completed, %Rak.Job{}})
    assert :ok = :timer.sleep(5)
    assert Stats.data() |> Map.get(:completed) == 3
  end

  test "increments on job retry events" do
    assert Stats.data() |> Map.get(:retries) == 0
    assert :ok = Event.notify({:retry, %Rak.Job{}})
    assert :ok = Event.notify({:retry, %Rak.Job{}})
    assert :ok = Event.notify({:retry, %Rak.Job{}})
    assert :ok = :timer.sleep(5)
    assert Stats.data() |> Map.get(:retries) == 3
  end

  test "increments on job failed events" do
    assert Stats.data() |> Map.get(:failed) == 0
    assert :ok = Event.notify({:failed, %Rak.Job{}})
    assert :ok = Event.notify({:failed, %Rak.Job{}})
    assert :ok = Event.notify({:failed, %Rak.Job{}})
    assert :ok = :timer.sleep(5)
    assert Stats.data() |> Map.get(:failed) == 3
  end
end
