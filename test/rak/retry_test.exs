defmodule Rak.RetryTest do
  use ExUnit.Case, async: true

  alias Rak.{
    Job,
    Retry
  }

  import Retry
  doctest Retry

  describe "retry_in/1" do
    test "returns the time to wait for the next job attempt" do
      assert Retry.retry_in(1) == 0
      assert Retry.retry_in(3) == 0
      assert Retry.retry_in(5) == 0
    end
  end

  describe "wait/0" do
    test "sleeps for the duration of `retry_in/1`" do
      now1 = :os.system_time(:milli_seconds)
      assert :ok = Retry.wait(10)
      now2 = :os.system_time(:milli_seconds)
      assert_in_delta(now1, now2, 5)
    end
  end
end
