defmodule Rak.Job.TrackerTest do
  use RakTest.Case

  alias Rak.{
    Job,
    Job.Generator,
    Job.Tracker,
    Persistence
  }

  setup_all do
    {:ok, _} = ensure_supervised(Persistence)
    {:ok, _} = ensure_supervised(Generator)
    {:ok, _} = ensure_supervised(Tracker)
    :ok
  end

  setup do
    :ok = Tracker.purge()
  end

  describe "expired jobs" do
    test "are flushed" do
      jobs =
        Enum.map(1..3, fn _ ->
          RakTest.Worker
          |> Job.new([])
          |> Job.perform_at(:os.system_time(:milli_seconds) + 100)
          |> Tracker.register()
        end)

      queue1 = Tracker.queue()
      Enum.each(jobs, &assert(&1 in queue1))

      :ok = :timer.sleep(250)

      queue2 = Tracker.queue()
      Enum.each(jobs, &refute(&1 in queue2))
    end
  end

  describe "queue/0" do
    test "returns all queued jobs" do
      jobs =
        Enum.map(1..5, fn _ ->
          RakTest.Worker
          |> Job.new([])
          |> Tracker.register()
        end)

      queue = Tracker.queue()
      Enum.each(jobs, &assert(&1 in queue))
    end
  end

  describe "flush/0" do
    test "enqueues all expired jobs" do
      scheduled =
        Enum.map(1..5, fn _ ->
          RakTest.Worker
          |> Job.new([])
          |> Job.perform_at(:os.system_time(:milli_seconds) + 100_000)
          |> Tracker.register()
        end)

      expired =
        Enum.map(1..5, fn _ ->
          RakTest.Worker
          |> Job.new([])
          |> Tracker.register()
        end)

      queue1 = Tracker.queue()
      Enum.each(scheduled, &assert(&1 in queue1))
      Enum.each(expired, &assert(&1 in queue1))

      assert :ok = Tracker.flush()

      queue2 = Tracker.queue()
      Enum.each(scheduled, &assert(&1 in queue2))
      Enum.each(expired, &refute(&1 in queue2))
    end
  end

  describe "reload/0" do
    test "reloads jobs from persistence" do
      jobs =
        Enum.map(1..5, fn _ ->
          RakTest.Worker
          |> Job.new([])
          |> Job.status(:scheduled)
          |> Job.id(Generator.generate())
          |> Persistence.insert()
        end)

      assert :ok = Tracker.purge()
      assert Enum.empty?(Tracker.queue())
      Tracker.reload()
      queue = Tracker.queue()
      Enum.each(jobs, &assert(&1 in queue))
    end
  end
end
