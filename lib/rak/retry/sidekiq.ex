defmodule Rak.Retry.Sidekiq do
  @moduledoc """
  Sidekiq-style Backoff Retry Strategy
  """
  use Rak.Retry

  @impl true
  def retry_in(attempt) do
    attempt
    |> :math.pow(4)
    |> Kernel.+(15)
    |> Kernel.+(:rand.uniform(30) * (attempt + 1))
    |> trunc()
  end
end
