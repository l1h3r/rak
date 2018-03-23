defmodule Rak.Retry.InstantTest do
  use ExUnit.Case, async: true
  alias Rak.Retry.Instant

  test "retry_in/1 returns an integer" do
    assert is_integer(Instant.retry_in(1))
  end
end
