defmodule Rak.Persistence.Mnesia.Setup do
  @moduledoc """
  Rak Persistence Mnesia Setup
  """
  use Rak.Util.Logger

  alias Rak.{
    Config,
    Error.SetupError,
    Job
  }

  @dir Application.get_env(:mnesia, :dir)

  @timeout Config.get([:mnesia, :timeout])

  @table Config.get([:mnesia, :table])

  @doc """
  Creates the Mnesia database.
  """
  @spec run!(nodes :: list(node())) :: :ok | no_return()
  def run!(nodes \\ [node()]) do
    :stopped = :mnesia.stop()
    :ok = remove_dir!(@dir)
    :ok = create_dir!(@dir)
    :ok = create_schema!(nodes)
    :ok = :mnesia.start()

    # Create the DB with Disk Copies
    opts = [
      disc_copies: nodes,
      type: :ordered_set,
      record_name: @table,
      access_mode: :read_write,
      attributes: [:key, :id, :attrs]
    ]

    :ok = create_table!(@table, opts)
    :ok = wait()
  end

  @doc """
  Waits for the Mnesia tables to become accessible.
  """
  @spec wait :: :ok
  def wait do
    :ok = :mnesia.wait_for_tables([@table], @timeout)
  end

  @doc """
  Resets the Mnesia table.
  """
  @spec reset :: :ok
  def reset do
    :ok = delete_table!(@table)
    :ok = create_table!(@table)
    :ok
  end

  @doc """
  Removes the existing Mnesia DB file and creates a new DB.
  """
  @spec reset! :: :ok
  def reset! do
    :stopped = :mnesia.stop()
    :ok = remove_dir!(@dir)
    :ok = :mnesia.start()
    :ok = reset()
  end

  @spec create_table!(table :: atom(), opts :: keyword()) :: :ok | no_return()
  def create_table!(table, opts \\ []) do
    case :mnesia.create_table(table, opts) do
      {:atomic, :ok} ->
        :ok = log(:debug, "[Mnesia] Created Table: #{inspect(table)}")
        :ok

      {:aborted, {:already_exists, ^table}} ->
        :ok = log(:debug, "[Mnesia] Table Exists: #{inspect(table)}")
        :ok

      {:aborted, reason} ->
        raise SetupError, inspect(reason)
    end
  end

  @spec delete_table!(table :: atom()) :: :ok | no_return()
  def delete_table!(table) do
    case :mnesia.delete_table(table) do
      {:atomic, :ok} ->
        :ok = log(:debug, "[Mnesia] Deleted Table: #{inspect(table)}")
        :ok

      {:aborted, {:no_exists, _}} ->
        :ok = log(:debug, "[Mnesia] Table Not Found: #{inspect(table)}")
        :ok

      error ->
        raise SetupError, inspect(error)
    end
  end

  @spec create_schema!(nodes :: list(node())) :: :ok | no_return()
  def create_schema!(nodes \\ [node()]) do
    case :mnesia.create_schema(nodes) do
      :ok ->
        :ok = log(:debug, "[Mnesia] Created Schema: #{inspect(nodes)}")
        :ok

      {:error, {_, {:already_exists, _}}} ->
        :ok = log(:debug, "[Mnesia] Schema Exists: #{inspect(nodes)}")
        :ok

      {:error, reason} ->
        raise SetupError, inspect(reason)
    end
  end

  @spec create_dir!(dir :: charlist() | nil) :: :ok | no_return()
  defp create_dir!(nil), do: :ok
  defp create_dir!(dir), do: :ok = File.mkdir_p!(dir)

  @spec remove_dir!(dir :: charlist() | nil) :: :ok | no_return()
  defp remove_dir!(nil), do: :ok

  defp remove_dir!(dir) do
    with files when is_list(files) <- File.rm_rf!(dir), do: :ok
  end
end
