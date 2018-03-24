defmodule Rak.Queue.ServerTest do
  use RakTest.Case

  alias Rak.{
    Job,
    Queue.Server
  }

  @name :test_queue

  setup do
    {:ok, pid} = ensure_supervised({Server, @name})
    [pid: pid]
  end

  test "status/1 returns the queue server state", %{pid: pid} do
    Enum.each(1..25, fn _ ->
      assert :ok = Server.request(pid, Job.new(RakTest.Worker2, []))
    end)

    Enum.each(1..5, fn _ ->
      assert :ok = Server.request(pid, Job.new(RakTest.Worker3, []))
    end)

    status = Server.status(pid)

    assert Keyword.get(status, :name) == @name
    assert Keyword.get(status, :running) == 8
    assert Keyword.get(status, :pending) == 22
    assert Keyword.get(status, :status) == :active
  end

  test "suspend/1 pauses job execution", %{pid: pid} do
    Enum.each(1..25, fn _ ->
      assert :ok = Server.request(pid, Job.new(RakTest.Worker, []))
    end)

    status1 = Server.status(pid)

    assert Keyword.get(status1, :running) == 1
    assert Keyword.get(status1, :pending) == 24
    assert Keyword.get(status1, :status) == :active

    assert :ok = Server.suspend(pid)

    # Wait for any current job to finish
    Server.wait(pid)

    status2 = Server.status(pid)

    assert Keyword.get(status2, :running) == 0
    assert Keyword.get(status2, :pending) == 24
    assert Keyword.get(status2, :status) == :suspended
  end

  test "resume/1 resumes job execution", %{pid: pid} do
    assert :ok = Server.suspend(pid)

    Enum.each(1..25, fn _ ->
      assert :ok = Server.request(pid, Job.new(RakTest.Worker, []))
    end)

    status1 = Server.status(pid)

    assert Keyword.get(status1, :running) == 0
    assert Keyword.get(status1, :pending) == 25
    assert Keyword.get(status1, :status) == :suspended

    assert :ok = Server.resume(pid)

    status2 = Server.status(pid)

    assert Keyword.get(status2, :running) == 1
    assert Keyword.get(status2, :pending) == 24
    assert Keyword.get(status2, :status) == :active
  end
end
