defmodule Rak.Persistence.Mnesia do
  @moduledoc """
  Rak Persistence Mnesia

  Provides job storage via Mnesia
  """
  use Rak.Persistence

  alias Rak.{
    Config,
    Job
  }

  @table Config.get([:mnesia, :table])

  def start_link(_ \\ []) do
    :ok = :mnesia.start()
    :ok = __MODULE__.Setup.wait()

    :ignore
  end

  def all do
    transaction(fn ->
      {@table, :_, :_}
      |> :mnesia.match_object()
      |> Enum.map(&to_job/1)
    end)
  end

  def find(jid) do
    transaction(fn ->
      @table
      |> to_row(&id_mapper(&1, jid))
      |> :mnesia.match_object()
      |> Enum.map(&to_job/1)
      |> List.first()
    end)
  end

  def by_status(status) do
    transaction(fn ->
      @table
      |> to_row(&status_mapper(&1, status))
      |> :mnesia.match_object()
      |> Enum.map(&to_job/1)
    end)
  end

  def destroy(jid) do
    transaction(fn ->
      :mnesia.delete(@table, jid, :write)
    end)
  end

  def insert(job) do
    transaction(fn ->
      :ok =
        @table
        |> to_row(job)
        |> :mnesia.write()

      job
    end)
  end

  def update(job) do
    transaction(fn ->
      :ok =
        @table
        |> to_row(job)
        |> :mnesia.write()

      job
    end)
  end

  def clear do
    case :mnesia.clear_table(@table) do
      {:atomic, :ok} -> :ok
      {:aborted, reason} -> {:error, reason}
    end
  end

  # ======= #
  # Private #
  # ======= #

  @spec status_mapper(key :: atom(), status :: atom()) :: {atom(), String.t() | atom()}
  defp status_mapper(:status, status), do: {:status, status}
  defp status_mapper(key, _), do: {key, :_}

  @spec id_mapper(key :: atom(), jid :: String.t()) :: {atom(), String.t() | atom()}
  defp id_mapper(:id, jid), do: {:id, jid}
  defp id_mapper(key, _), do: {key, :_}

  @spec transaction(fun :: fun()) :: any() | {:error, String.t()}
  defp transaction(fun) do
    case :mnesia.sync_transaction(fun) do
      {:atomic, result} ->
        result

      {:aborted, reason} ->
        {:error, :mnesia.error_description({:aborted, reason})}
    end
  end

  @spec to_row(table :: atom(), job :: Job.t()) :: tuple()
  @spec to_row(table :: atom(), mapper :: fun()) :: tuple()
  defp to_row(table, %Job{} = job), do: to_row(table, &{&1, Map.fetch!(job, &1)})

  defp to_row(table, mapper) do
    attrs = Enum.map(Job.keys(), mapper)

    {table, Keyword.get(attrs, :id), attrs}
  end

  @spec to_job(tuple :: tuple()) :: Job.t()
  defp to_job({@table, _, attrs}), do: struct!(Job, attrs)
end
