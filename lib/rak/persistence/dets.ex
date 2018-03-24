defmodule Rak.Persistence.DETS do
  @moduledoc """
  Rak Persistence DETS

  Provides job storage via DETS
  """
  use Rak.Persistence
  alias Rak.Config

  @dir Config.get([:dets, :dir])

  @table Config.get(:app)

  @table_opts [
    {:access, :read_write},
    {:file, '#{@dir}/#{@table}'}
  ]

  def start_link(_ \\ []) do
    :ok = File.mkdir_p!(@dir)
    {:ok, @table} = :dets.open_file(@table, @table_opts)

    :ignore
  end

  def all do
    @table
    |> :dets.select([{:"$1", [], [:"$1"]}])
    |> Enum.map(&elem(&1, 1))
  end

  def find(jid) do
    case :dets.lookup(@table, jid) do
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
    |> :dets.select(match)
    |> Enum.map(&elem(&1, 1))
  end

  def destroy(jid), do: @table |> :dets.delete(jid) |> result(:destroy)

  def insert(%{id: jid} = job) do
    with :ok <- @table |> :dets.insert_new({jid, job}) |> result(:insert), do: job
  end

  def update(%{id: jid} = job) do
    with :ok <- @table |> :dets.insert({jid, job}) |> result(:update), do: job
  end

  def clear, do: @table |> :dets.delete_all_objects() |> result(:clear)

  @spec result(result :: boolean() | :ok | term(), name :: atom()) :: :ok | no_return()
  defp result(:ok, _), do: :ok
  defp result(true, _), do: :ok
  defp result(false, name), do: raise(RuntimeError, "DETS operation failed: #{name}")
  defp result({:error, reason}, _), do: raise(RuntimeError, inspect(reason))
end
