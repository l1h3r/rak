defmodule Rak.Job.GeneratorTest do
  use RakTest.Case
  alias Rak.Job.Generator

  setup_all do
    {:ok, _} = ensure_supervised(Generator)
    :ok
  end

  test "generates a stores keys" do
    Enum.each(1..100, fn _ ->
      key = Generator.generate()
      assert key in Generator.keys()
    end)
  end
end
