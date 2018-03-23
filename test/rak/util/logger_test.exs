defmodule Rak.Util.LoggerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias Rak.Util.Logger

  defmodule Speaker do
    use Logger
    def speak, do: log(:info, "hello")
  end

  describe "log/2" do
    test "logs error message" do
      captured = capture_log(fn -> Speaker.speak() end)
      assert captured =~ "hello"
    end

    test "adds prefix to error message" do
      captured = capture_log(fn -> Speaker.speak() end)
      assert captured =~ "[RAK]"
    end
  end
end
