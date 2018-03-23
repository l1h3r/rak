defmodule Rak.Retry.Backoff do
  @moduledoc """
  Backoff Retry Strategy

  Retries failed jobs with increasing delay
    * 250ms - 4sec - 20sec - 60sec - 150sec
  """
  use Rak.Retry

  def retry_in(attempt) do
    attempt
    |> :math.pow(4)
    |> Kernel.*(250)
    |> trunc()
  end
end
