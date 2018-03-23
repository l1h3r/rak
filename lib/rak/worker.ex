defmodule Rak.Worker do
  @moduledoc """
  Rak Worker
  """
  alias Rak.{
    Job,
    Error.WorkerError
  }

  @callback perform :: any()

  @callback perform(args :: list()) :: any()

  @callback on_completed(job :: Job.t()) :: :ok

  @callback on_failed(job :: Job.t(), reason :: String.t(), stack :: list()) :: :ok

  defmacro __using__(opts \\ []) do
    quote do
      use Rak.Util.Logger

      alias Rak.{
        Job,
        Error.WorkerError,
        Worker
      }

      @after_compile __MODULE__

      @concurrency unquote(opts[:concurrency] || :infinite)

      @max_retries unquote(opts[:max_retries])

      @behaviour Worker

      @spec concurrency :: non_neg_integer() | :infinite
      def concurrency, do: @concurrency

      @spec max_retries :: non_neg_integer() | :infinite | nil
      def max_retries, do: @max_retries

      @spec perform(args :: list()) :: any()
      def perform(args \\ []), do: nil

      @spec on_completed(job :: Job.t()) :: :ok
      def on_completed(job), do: :ok

      @spec on_failed(job :: Job.t(), reason :: String.t(), stack :: list()) :: :ok
      def on_failed(job, reason, stack), do: log_error(job, reason, stack)

      @spec log_error(job :: Job.t(), reason :: String.t(), stack :: list()) :: :ok
      defp log_error(job, reason, stack) do
        stacktrace = Exception.format_stacktrace(stack)
        message = "Failed:\n\n#{inspect(reason)}\n\n#{stacktrace}"
        log(:error, job, message)
      end

      defoverridable Worker

      @spec __rak_worker__ :: boolean()
      def __rak_worker__, do: true

      @spec __after_compile__(env :: Macro.Env.t(), bytecode :: binary()) :: no_return()
      def __after_compile__(_, _) do
        # Raise error if given invalid concurrency
        unless @concurrency == :infinite or (is_integer(@concurrency) and @concurrency > 0) do
          raise WorkerError, "#{__MODULE__} has an invalid value for `concurrency`"
        end

        # Raise error if given invalid retries
        unless @max_retries in [nil, :infinite] or (is_integer(@max_retries) and @max_retries > 0) do
          raise WorkerError, "#{__MODULE__} has an invalid value for `max_retries`"
        end
      end
    end
  end

  @doc """
  Returns true if the given module is a valid worker
  """
  @spec valid?(module :: module()) :: boolean()
  def valid?(module) do
    module.__rak_worker__()
  rescue
    UndefinedFunctionError ->
      false
  end

  @doc """
  Raises an error if the given module is not a valid worker
  """
  @spec validate!(module :: module()) :: :ok | no_return()
  def validate!(module) do
    if valid?(module) do
      :ok
    else
      raise WorkerError, "#{module} is not a valid worker"
    end
  end
end
