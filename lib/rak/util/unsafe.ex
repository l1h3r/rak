defmodule Rak.Util.Unsafe do
  @moduledoc """
  Rak Util Unsafe

  Runs the given function as a spawned process and captures the response.
  """
  @type captured :: :ok | {:error, String.t(), list()}
  @type execution :: {module :: module(), fun :: fun(), args :: any()}

  @spec run(fun :: fun(), timeout :: timeout()) :: captured()
  @spec run(execution :: execution(), timeout :: timeout()) :: captured()
  def run(fun, timeout \\ :infinity)
  def run({module, fun, args}, timeout), do: run(fn -> apply(module, fun, args) end, timeout)

  def run(fun, timeout) when is_function(fun) do
    ref = self()

    {_, _} = spawn_monitor(fn -> send(ref, capture(fun)) end)

    wait(timeout)
  end

  @spec capture(fun :: fun()) :: captured()
  defp capture(fun) do
    fun.()
    :ok
  rescue
    error -> {:error, error_message(error), System.stacktrace()}
  end

  @spec wait(timeout :: timeout()) :: no_return()
  defp wait(timeout) do
    receive do
      :ok ->
        :ok

      {:error, _, _} = error ->
        error

      {:DOWN, _, :process, _, :normal} ->
        wait(timeout)

      {:DOWN, _, :process, _, error} ->
        {:error, "[Unsafe] DOWN: #{error_message(error)}", System.stacktrace()}
    after
      timeout ->
        {:error, "[Unsafe] Timeout: #{inspect(timeout)}", System.stacktrace()}
    end
  end

  @spec error_message(message :: struct() | String.t()) :: String.t()
  defp error_message(%{message: message}), do: message
  defp error_message(message), do: inspect(message)
end
