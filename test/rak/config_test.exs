defmodule Rak.ConfigTest do
  use ExUnit.Case, async: true
  alias Rak.Config
  import Config
  doctest Config

  describe "all/0" do
    test "returns all config values" do
      mnesia = Application.get_env(:rak, :mnesia, [])
      update = Keyword.put(mnesia, :table, HelloTable)

      assert :ok = Application.put_env(:rak, :mnesia, update)

      all = Config.all()

      # Test common values
      assert Keyword.has_key?(all, :app)
      assert Keyword.has_key?(all, :queues)
      assert Keyword.has_key?(all, :retry_strategy)

      # Test nested values
      assert get_in(all, [:mnesia, :timeout]) == 5000
      assert get_in(all, [:mnesia, :table]) == HelloTable

      # Restore app env
      assert :ok = Application.put_env(:rak, :mnesia, mnesia)
    end

    test "returns a default value when not set" do
      queues = Application.get_env(:rak, :queues)
      assert :ok = Application.put_env(:rak, :queues, nil)
      assert [:default] = Keyword.get(Config.all(), :queues)
      assert :ok = Application.put_env(:rak, :queues, queues)
    end

    test "does not override user-set with default values" do
      queues = Application.get_env(:rak, :queues)
      assert :ok = Application.put_env(:rak, :queues, [:my_queue])
      assert [:my_queue] = Keyword.get(Config.all(), :queues)
      assert :ok = Application.put_env(:rak, :queues, queues)
    end
  end
end
