defmodule Rak.JobTest do
  use RakTest.Case

  alias Rak.{
    Job,
    Job.Generator,
    Persistence
  }

  import Job
  doctest Job

  setup_all do
    {:ok, _} = ensure_supervised(Generator)
    {:ok, _} = ensure_supervised(Persistence)
    :ok
  end

  describe "keys/0" do
    test "returns all struct attributes" do
      keys = keys()

      %Job{}
      |> Map.from_struct()
      |> Map.keys()
      |> Enum.each(&assert(&1 in keys))
    end
  end

  describe "statuses/0" do
    test "returns all valid job statuses" do
      Enum.each(statuses(), &assert(status?(&1)))
    end
  end
end
