defmodule Rak.Persistence.Memory do
  @moduledoc """
  Rak Persistence Memory

  Provides in-memory storage for jobs
  """
  use Agent
  use Rak.Persistence

  # ====== #
  # Client #
  # ====== #

  @impl true
  def start_link(_ \\ []), do: Agent.start_link(fn -> [] end, name: __MODULE__)

  @impl true
  def all, do: Agent.get(__MODULE__, & &1)

  @impl true
  def find(jid), do: Agent.get(__MODULE__, &find(&1, jid))

  @impl true
  def by_status(status), do: Agent.get(__MODULE__, &by_status(&1, status))

  @impl true
  def destroy(jid), do: Agent.update(__MODULE__, &destroy(&1, jid))

  @impl true
  def insert(job) do
    with :ok <- Agent.update(__MODULE__, &[job | &1]), do: job
  end

  @impl true
  def update(job) do
    with :ok <- Agent.update(__MODULE__, &update(&1, job)), do: job
  end

  @impl true
  def clear, do: Agent.update(__MODULE__, fn _ -> [] end)

  # ======= #
  # Private #
  # ======= #

  defp find(state, jid), do: Enum.find(state, &match?(%{id: ^jid}, &1))

  defp by_status(state, status), do: Enum.filter(state, &match?(%{status: ^status}, &1))

  defp destroy(state, jid), do: Enum.reject(state, &match?(%{id: ^jid}, &1))

  defp update(_, _)
  defp update([], _), do: []
  defp update([%{id: mid} | tail], %{id: jid} = job) when mid == jid, do: [job | tail]
  defp update([head | tail], job), do: [head | update(tail, job)]
end
