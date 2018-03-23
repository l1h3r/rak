defmodule Rak.Queue.ServerTest do
  use RakTest.Case

  alias Rak.{
    Job,
    Queue.Server
  }

  @name :test_queue

  setup_all do
    {:ok, pid} = ensure_supervised({Server, @name})
    [pid: pid]
  end

  test "status/0 returns the queue server state", %{pid: pid} do
    Enum.each(1..25, fn _ ->
      assert :ok = Server.request(pid, Job.new(RakTest.Worker2, []))
    end)

    Enum.each(1..5, fn _ ->
      assert :ok = Server.request(pid, Job.new(RakTest.Worker3, []))
    end)

    status = Server.status(pid)

    assert Keyword.keyword?(status)
    assert Keyword.get(status, :name) == @name
    assert Keyword.get(status, :running) == 8
    assert Keyword.get(status, :pending) == 22
  end
end
