defmodule Rak.Retry.SidekiqTest do
  use ExUnit.Case, async: true
  alias Rak.Retry.Sidekiq

  test "retry_in/1 returns an integer" do
    assert is_integer(Sidekiq.retry_in(1))
  end
end
