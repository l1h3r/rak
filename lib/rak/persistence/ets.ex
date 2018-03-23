defmodule Rak.Persistence.ETS do
  @moduledoc """
  Rak Persistence ETS

  Provides job storage via ETS
  """
  use Rak.Persistence
  alias Rak.Config

  @table Config.get(:app)

  @table_opts [
    :public,
    :named_table
  ]

  def start_link(_ \\ []) do
    @table = :ets.new(@table, @table_opts)

    :ignore
  end

  def all do
    @table
    |> :ets.select([{:"$1", [], [:"$1"]}])
    |> Enum.map(&elem(&1, 1))
  end

  def find(jid) do
    case :ets.lookup(@table, jid) do
      [{^jid, match}] -> match
      [] -> nil
    end
  end

  def by_status(status) do
    match = [
      {
        {:_, %{status: :"$1"}},
        [{:"=:=", {:const, status}, :"$1"}],
        [:"$_"]
      }
    ]

    @table
    |> :ets.select(match)
    |> Enum.map(&elem(&1, 1))
  end

  def destroy(jid), do: @table |> :ets.delete(jid) |> result(:destroy)

  def insert(%{id: jid} = job) do
    with :ok <- @table |> :ets.insert_new({jid, job}) |> result(:insert), do: job
  end

  def update(%{id: jid} = job) do
    with :ok <- @table |> :ets.insert({jid, job}) |> result(:update), do: job
  end

  def clear, do: @table |> :ets.delete_all_objects() |> result(:clear)

  @spec result(result :: boolean() | :ok | term(), name :: atom()) :: :ok | no_return()
  defp result(:ok, _), do: :ok
  defp result(true, _), do: :ok
  defp result(false, name), do: raise(RuntimeError, "ETS operation failed: #{name}")
  defp result({:error, reason}, _), do: raise(RuntimeError, inspect(reason))
end
