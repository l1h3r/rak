defmodule Rak.Job.RunnerTest do
  use RakTest.Case

  alias Rak.{
    Job,
    Job.Generator,
    Job.Runner,
    Persistence,
    Queue
  }

  setup_all do
    {:ok, _} = ensure_supervised(Queue.Supervisor)
    {:ok, _} = ensure_supervised(Persistence)
    {:ok, _} = ensure_supervised(Generator)
    {:ok, _} = ensure_supervised(Runner)
    :ok
  end

  describe "register/1" do
    test "removes completed jobs" do
      job = Job.create(RakTest.Worker, [], status: :enqueued)

      assert %Job{status: :enqueued} = Runner.register(job)
      assert :ok = :timer.sleep(100)
      assert Persistence.find(job.id) == nil
    end

    test "retries failures according to strategy" do
      job = Job.create(RakTest.Worker, :fail, status: :enqueued)

      assert %Job{status: :enqueued} = Runner.register(job)
      assert :ok = :timer.sleep(100)
      assert %Job{status: :failed} = Persistence.find(job.id)
    end
  end
end
