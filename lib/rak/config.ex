defmodule Rak.Config do
  @moduledoc """
  Rak Config
  """
  alias Rak.{
    Persistence,
    Retry,
    Util
  }

  @app :rak

  @defaults [
    app: @app,
    # The ETS table name for persisting stats.
    stats_table: :rak_stats,
    # The list of available queue namespaces.
    queues: [:default],
    # The default worker queue.
    default_queue: :default,
    # The timeout for executing job processes.
    timeout: :infinity,
    # The max number of times a failed job will be retried.
    max_retries: 5,
    # The module for handling job persistence.
    storage_adapter: Persistence.Memory,
    # The strategy for retrying failed jobs. See `Rak.Retry`.
    retry_strategy: Retry.Instant,
    # The interval to flush scheduled jobs, in milliseconds.
    flush_interval: 100,
    # Mnesia storage settings
    mnesia: [
      timeout: 5000,
      table: Persistence.Mnesia.DB
    ]
  ]

  @doc """
  Returns a keyword list of all config values.
  """
  def all, do: Util.Access.merge(@defaults, get(:all))

  @doc """
  Fetches a value from the application config.

  An optional default value can be provided if desired.

  ## Examples

      iex> get(:app)
      :rak

      iex> get(:retry_strategy)
      Rak.Retry.Instant

      iex> get([:nonexistent, :nonexistent], :path)
      :path

      iex> get(:nonexistent)
      nil

      iex> get(:nonexistent, :default)
      :default

  """
  @spec get(key :: atom() | list(), default :: term() | nil) :: term()
  def get(_, _ \\ nil)

  def get(:app, _), do: @app

  def get(:all, _), do: :app |> get() |> Application.get_all_env()

  def get(path, default) do
    :all
    |> get()
    |> Util.Access.get(path, fn ->
      default || Util.Access.get(@defaults, path)
    end)
  end

  @doc """
  Same as get/2, but returns the result as an integer.

  If the value cannot be converted to an integer, the
  default is returned instead.

  ## Examples

      iex> get_int(:app)
      0

      iex> get_int(:max_retries)
      5

      iex> get_int(:nonexistent)
      0

      iex> get_int(:nonexistent, 10)
      10

  """
  @spec get_int(key :: atom(), default :: integer()) :: integer()
  def get_int(key, default \\ 0), do: key |> get() |> Util.Integer.safe_parse(default)
end
