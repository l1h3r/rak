defmodule Rak.Util.Logger do
  @moduledoc """
  Rak Util Logger
  """
  defmacro __using__(_) do
    quote location: :keep do
      require Logger
      alias Rak.Job

      @levels [:debug, :info, :warn, :error]

      @spec log(level :: atom(), job :: Job.t(), message :: String.t()) :: :ok
      def log(level, job, message) when level in @levels do
        Logger.log(level, to_message(message, job))
      end

      @spec log(level :: atom(), message :: String.t()) :: :ok
      def log(level, message) when level in @levels do
        Logger.log(level, to_message(message))
      end

      @spec to_message(message :: String.t(), job :: Job.t() | nil) :: String.t()
      defp to_message(_, _ \\ nil)
      defp to_message(message, nil), do: "[RAK] #{inspect(__MODULE__)} - #{message}"
      defp to_message(message, job), do: to_message("#{message} for: #{inspect(job)}")
    end
  end
end
