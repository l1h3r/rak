defmodule Rak.Retry do
  @moduledoc """
  Rak Retry

  Defines the specification for a job retry strategy
  """
  alias Rak.{
    Config,
    Job
  }

  @callback retry_in(attempt :: integer()) :: integer()

  defmacro __using__(_) do
    quote do
      alias Rak.Retry

      @behaviour Retry

      @impl true
      def retry_in(_), do: 0

      defoverridable Retry
    end
  end

  @strategy Config.get(:retry_strategy)

  @max_retries Config.get_int(:max_retries)

  defdelegate retry_in(attempt), to: @strategy

  @spec strategy :: module()
  def strategy, do: @strategy

  @doc """
  Checks if the job can be retried for the given `attempt`.

  ## Examples

      iex> retry?(%Job{module: RakTest.Worker}, 1)
      true

      iex> retry?(%Job{module: RakTest.Worker}, 2)
      false

  """
  @spec retry?(job :: Job.t(), attempt :: integer()) :: boolean()
  def retry?(%Job{module: module}, attempt), do: attempt <= (module.max_retries() || @max_retries)

  @spec wait(attempt :: integer()) :: :ok
  def wait(attempt) when is_integer(attempt), do: attempt |> retry_in() |> :timer.sleep()
end
