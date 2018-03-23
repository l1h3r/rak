defmodule Rak.Util.UnsafeTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias Rak.Util.Unsafe

  defmodule Helper do
    def test, do: IO.puts("test")
  end

  describe "run/1" do
    test "performs the given function and returns `:ok`" do
      captured =
        capture_io(fn ->
          assert :ok = Unsafe.run(fn -> IO.puts("test") end)
        end)

      assert captured =~ "test"
    end

    test "returns an error if the spawned process raises an exception" do
      assert {:error, "invalid", _} = Unsafe.run(fn -> raise "invalid" end)

      assert {:error, "[Unsafe] DOWN: :killed", _} =
               Unsafe.run(fn -> Process.exit(self(), :kill) end)
    end

    test "performs module.fun(args) when given {module, fun, args}" do
      captured =
        capture_io(fn ->
          assert :ok = Unsafe.run({Helper, :test, []})
        end)

      assert captured =~ "test"
    end

    test "with timeout option" do
      assert {:error, "[Unsafe] Timeout: 10", _} = Unsafe.run(fn -> :timer.sleep(1000) end, 10)
    end
  end
end
