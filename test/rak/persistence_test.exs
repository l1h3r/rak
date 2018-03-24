defmodule Rak.PersistenceTest do
  use RakTest.Shared

  persistence do
    describe "all/0" do
      test "returns all jobs", %{adapter: adapter} do
        jobs = insert_jobs(adapter)
        all = adapter.all()

        Enum.each(jobs, &assert(&1 in all))
      end

      test "returns empty list", %{adapter: adapter} do
        assert adapter.all() == []
      end
    end

    describe "find/1" do
      test "returns job", %{adapter: adapter} do
        job = insert_job(adapter)
        assert ^job = adapter.find(job.id)
      end

      test "returns nil", %{adapter: adapter} do
        assert adapter.find("banana") == nil
      end
    end

    describe "by_status/1" do
      test "returns all jobs with the given status", %{adapter: adapter} do
        enqueued = insert_jobs(adapter)
        scheduled = insert_jobs(adapter, status: :scheduled)
        enqueued2 = adapter.by_status(:enqueued)
        scheduled2 = adapter.by_status(:scheduled)

        Enum.each(enqueued, &assert(&1 in enqueued2))
        Enum.each(scheduled, &assert(&1 in scheduled2))
      end

      test "returns empty list", %{adapter: adapter} do
        assert adapter.by_status(:banana) == []
      end
    end

    describe "destroy/1" do
      test "removes job", %{adapter: adapter} do
        job = insert_job(adapter)
        assert ^job = adapter.find(job.id)
        assert :ok = adapter.destroy(job.id)
        assert adapter.find(job.id) == nil
      end
    end

    describe "insert/1" do
      test "inserts and returns job", %{adapter: adapter} do
        job = new_job()
        assert adapter.find(job.id) == nil
        assert ^job = adapter.insert(job)
        assert ^job = adapter.find(job.id)
      end
    end

    describe "update/1" do
      test "updates and returns job", %{adapter: adapter} do
        job =
          adapter
          |> insert_job()
          |> Job.status(:failed)
          |> Job.error("some error")

        assert ^job = adapter.update(job)
        assert %Job{status: status, error: error} = adapter.find(job.id)
        assert {:failed, "some error"} = {status, error}
      end
    end

    # ======= #
    # Helpers #
    # ======= #

    defp insert_jobs(adapter, opts \\ []) do
      count = Keyword.get(opts, :count, 5)
      status = Keyword.get(opts, :status, :enqueued)

      Enum.map(1..count, fn _ ->
        new_job()
        |> Job.status(status)
        |> adapter.insert()
      end)
    end

    defp insert_job(adapter), do: adapter.insert(new_job())

    defp new_job, do: RakTest.Worker |> Job.new([]) |> Job.id()
  end
end

defmodule Rak.Persistence.BaseTest do
  use Rak.PersistenceTest, adapter: Rak.Persistence
end

defmodule Rak.Persistence.MemoryTest do
  use Rak.PersistenceTest, adapter: Rak.Persistence.Memory
end

defmodule Rak.Persistence.ETSTest do
  use Rak.PersistenceTest, adapter: Rak.Persistence.ETS
end

defmodule Rak.Persistence.DETSTest do
  use Rak.PersistenceTest, adapter: Rak.Persistence.DETS
end

defmodule Rak.Persistence.MnesiaTest do
  use Rak.PersistenceTest, adapter: Rak.Persistence.Mnesia
  import ExUnit.CaptureIO
  alias Rak.Config
  alias Mix.Tasks.Rak.Setup

  @dir Application.get_env(:mnesia, :dir)

  @table Config.get([:mnesia, :table])

  test "Mix task creates the Mnesia DB" do
    captured1 = capture_io(&:mnesia.info/0)
    assert captured1 =~ ~r/Directory "#{Path.expand(@dir)}" is NOT used/
    assert captured1 =~ ~r/ram_copies\s+=.+#{@table}.+#{@table}/s

    assert :ok = Setup.run("")

    captured2 = capture_io(&:mnesia.info/0)
    assert captured2 =~ ~r/Directory "#{Path.expand(@dir)}" is used/
    assert captured2 =~ ~r/disc_copies\s+=.+#{@table}.+#{@table}/s
  end
end
