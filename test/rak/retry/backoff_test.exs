defmodule Rak.Retry.BackoffTest do
  use ExUnit.Case, async: true
  alias Rak.Retry.Backoff

  test "retry_in/1 returns an integer" do
    assert is_integer(Backoff.retry_in(1))
  end
end
