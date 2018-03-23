defmodule Rak.Error do
  @moduledoc """
  Rak Error
  """
  defmodule WorkerError do
    defexception [:message]
  end

  defmodule SetupError do
    defexception [:message]
  end
end
