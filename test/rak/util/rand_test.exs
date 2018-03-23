defmodule Rak.Util.RandTest do
  use ExUnit.Case, async: true
  alias Rak.Util.Rand

  describe "unique/1" do
    test "sets a unique value" do
      count = 10_000
      {_, unique} = Rand.unique(%{})
      assert map_size(unique) == 1

      reduced =
        Enum.reduce(1..count, unique, fn _, acc ->
          acc
          |> Rand.unique()
          |> elem(1)
        end)

      assert map_size(reduced) == count + 1
    end
  end
end
