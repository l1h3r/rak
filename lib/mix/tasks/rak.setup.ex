defmodule Mix.Tasks.Rak.Setup do
  @moduledoc """
  Creates an Mnesia DB for Rak
  """
  use Mix.Task
  alias Rak.Persistence.Mnesia.Setup

  @shortdoc "Creates an Mnesia DB for Rak"

  @callback run(args :: list(binary())) :: any()
  def run(_), do: Setup.run!()
end
