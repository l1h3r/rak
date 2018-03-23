ExUnit.start(capture_log: true)

defmodule RakTest.Case do
  defmacro __using__(opts \\ []) do
    quote do
      @async Keyword.get(unquote(opts), :async, false)

      use ExUnit.Case, async: @async

      require RakTest.Case
      import RakTest.Case

      def ensure_supervised({name, args}) do
        case Process.whereis(name) do
          nil -> start_supervised({name, args})
          pid -> {:ok, pid}
        end
      end

      def ensure_supervised(name), do: ensure_supervised({name, []})

      def ensure_restarted(name) do
        pid = Process.whereis(name)
        ref = Process.monitor(pid)

        Process.exit(pid, :kill)

        receive do
          {:DOWN, ^ref, :process, ^pid, :killed} ->
            refute Process.alive?(pid)
            assert :ok = :timer.sleep(1)
            assert name |> Process.whereis() |> is_pid()

            :ok
        after
          1000 ->
            raise :timeout
        end
      end
    end
  end
end

defmodule RakTest.Worker do
  use Rak.Worker, concurrency: 1, max_retries: 1
  def perform(:fail), do: raise("fail")
  def perform(_), do: :ok
end

defmodule RakTest.Worker2 do
  use Rak.Worker, concurrency: 3
  def perform(:fail), do: raise("fail")
  def perform(_), do: :ok
end

defmodule RakTest.Worker3 do
  use Rak.Worker, concurrency: :infinite
  def perform(:fail), do: raise("fail")
  def perform(_), do: :ok
end

defmodule RakTest.Shared do
  defmacro __using__(_) do
    quote do
      alias RakTest.Shared
      require Shared
      import Shared
    end
  end

  defmacro persistence(do: block) do
    quote do
      defmacro __using__(opts) do
        block = unquote(Macro.escape(block))

        quote do
          use RakTest.Case
          alias Rak.Job

          @moduletag unquote(opts)

          @adapter Keyword.get(unquote(opts), :adapter)

          setup_all do
            if @adapter == Rak.Persistence.Mnesia do
              :ok = @adapter.Setup.reset!()
            end

            {:ok, _} = ensure_supervised(Job.Generator)
            {:ok, _} = ensure_supervised(@adapter)

            :ok
          end

          setup do
            if @adapter == Rak.Persistence.Mnesia do
              :ok = @adapter.Setup.reset()
              :ok = @adapter.Setup.wait()
            end

            :ok = @adapter.clear()
          end

          unquote(block)
        end
      end
    end
  end
end
