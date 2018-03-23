defmodule Rak.Util.Info do
  @moduledoc """
  Rak Util Info
  """
  alias Rak.{
    Config,
    Job.Generator,
    Persistence,
    Queue,
    Queue.Server,
    Retry,
    Stats
  }

  @doc """
  Returns useful info for debugging.
  """
  @spec info :: keyword()
  def info do
    [
      alive: alive?(Rak.Supervisor),
      config: Config.all(),
      jobs: [
        keys: Generator.keys() |> Enum.count(),
        stats: Stats.basic()
      ],
      persistence: [
        adapter: Persistence.adapter(),
        spec: Persistence.child_spec([])
      ],
      processes: processes(Rak.Supervisor),
      queues:
        Queue.Supervisor
        |> Supervisor.which_children()
        |> Enum.map(&(&1 |> elem(1) |> Server.status())),
      retry: [
        strategy: Retry.strategy()
      ],
      system: [
        architecture: :system_architecture |> :erlang.system_info() |> to_string(),
        threads: :erlang.system_info(:threads),
        thread_pool_size: :erlang.system_info(:thread_pool_size),
        version: [
          elixir: System.version(),
          erts: :version |> :erlang.system_info() |> to_string(),
          otp: :otp_release |> :erlang.system_info() |> to_string()
        ]
      ]
    ]
  end

  @doc """
  Returns true if the process (by `name`) is registered and alive.
  """
  @spec alive?(name :: atom()) :: boolean()
  def alive?(name) do
    case Process.whereis(name) do
      nil -> false
      pid -> Process.alive?(pid)
    end
  end

  @spec processes(supervisor :: Supervisor.supervisor()) :: keyword()
  defp processes(supervisor) do
    supervisor
    |> Supervisor.which_children()
    |> Enum.map(fn
      {name, pid, :supervisor, _} ->
        [name: name, pid: pid, type: :supervisor, children: processes(name)]

      {name, pid, type, _} ->
        [name: name, pid: pid, type: type]
    end)
  end
end
