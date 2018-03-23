defmodule Rak.Job.SupervisorTest do
  use RakTest.Case

  alias Rak.{
    Job.Event,
    Job.Generator,
    Job.Runner,
    Job.Tracker,
    Job.Supervisor,
    Persistence
  }

  setup_all do
    {:ok, _} = ensure_supervised(Persistence)
    {:ok, _} = ensure_supervised(Supervisor)
    :ok
  end

  test "restarts worker on crash" do
    assert :ok = ensure_restarted(Event)
    assert :ok = ensure_restarted(Generator)
    assert :ok = ensure_restarted(Runner)
    assert :ok = ensure_restarted(Tracker)
  end
end
