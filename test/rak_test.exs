defmodule RakTest do
  use RakTest.Case

  alias Rak.{
    Job,
    Util.Datetime
  }

  setup_all do
    {:ok, _} = ensure_supervised(Rak)
    :ok
  end

  describe "enqueue/3" do
    test "enqueues a job" do
      job = Rak.enqueue(RakTest.Worker, [])
      assert %Job{status: :enqueued} = job
    end

    test "optional queue" do
      job = Rak.enqueue(RakTest.Worker, :ok, queue: :default)
      assert %Job{queue: :default} = job
    end
  end

  describe "enqueue_in/4" do
    test "enqueues a scheduled job to run after the given delay" do
      offset = :os.system_time(:milli_seconds) + 5000
      job = Rak.enqueue_in(RakTest.Worker, [], 5000)
      assert %Job{status: :scheduled} = job
      assert_in_delta(job.perform_at, offset, 5)
    end

    test "delay in seconds" do
      offset = :os.system_time(:milli_seconds) + 5000
      job = Rak.enqueue_in(RakTest.Worker, [], {:seconds, 5})
      assert %Job{status: :scheduled} = job
      assert_in_delta(job.perform_at, offset, 5)
    end

    test "delay in minutes" do
      offset = :os.system_time(:milli_seconds) + 120_000
      job = Rak.enqueue_in(RakTest.Worker, [], {:minutes, 2})
      assert %Job{status: :scheduled} = job
      assert_in_delta(job.perform_at, offset, 5)
    end

    test "delay in hours" do
      offset = :os.system_time(:milli_seconds) + 10_800_000
      job = Rak.enqueue_in(RakTest.Worker, [], {:hours, 3})
      assert %Job{status: :scheduled} = job
      assert_in_delta(job.perform_at, offset, 5)
    end

    test "optional queue" do
      job = Rak.enqueue_in(RakTest.Worker, :ok, 500, queue: :background)
      assert %Job{queue: :background} = job
    end

    test "invalid delay" do
      assert_raise ArgumentError, "Invalid delay: []", fn ->
        Rak.enqueue_in(RakTest.Worker, :ok, [])
      end
    end
  end

  describe "enqueue_at/4" do
    test "enqueues a scheduled job to run at the given time" do
      at = :os.system_time(:milli_seconds) + 5000
      job = Rak.enqueue_at(RakTest.Worker, [], at)
      assert %Job{status: :scheduled} = job
      assert %Job{perform_at: ^at} = job
    end

    test "time as datetime struct" do
      datetime = "2018-03-20T00:00:00Z" |> DateTime.from_iso8601() |> elem(1)
      unix = Datetime.to_unix(datetime)
      job = Rak.enqueue_at(RakTest.Worker, [], datetime)
      assert %Job{perform_at: ^unix} = job
    end

    test "time as naive datetime struct" do
      datetime = "2018-03-20T00:00:00" |> NaiveDateTime.from_iso8601!()
      unix = Datetime.to_unix(datetime)
      job = Rak.enqueue_at(RakTest.Worker, [], datetime)
      assert %Job{perform_at: ^unix} = job
    end

    test "optional queue" do
      job =
        Rak.enqueue_at(
          RakTest.Worker,
          :ok,
          :os.system_time(:milli_seconds) + 500,
          queue: :immediate
        )

      assert %Job{queue: :immediate} = job
    end

    test "invalid datetime" do
      assert_raise ArgumentError, "Invalid datetime: :datetime", fn ->
        Rak.enqueue_at(RakTest.Worker, :ok, :datetime)
      end
    end
  end
end
