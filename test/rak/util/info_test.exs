defmodule Rak.Util.InfoTest do
  use RakTest.Case
  alias Rak.Util.Info

  @keys [
    {:alive, true},
    :config,
    :jobs,
    :persistence,
    :processes,
    :queues,
    :retry,
    :system
  ]

  setup_all do
    {:ok, _} = ensure_supervised(Rak)
    :ok
  end

  describe "info/0" do
    test "returns application info" do
      info = Info.info()

      Enum.each(@keys, fn
        {key, value} -> assert {key, value} in info
        key -> assert(key in Keyword.keys(info))
      end)
    end
  end
end
