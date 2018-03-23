defmodule Rak.Retry.Instant do
  @moduledoc """
  Instant Retry Strategy

  Retries failed jobs instantly, without delay
  """
  use Rak.Retry
end
