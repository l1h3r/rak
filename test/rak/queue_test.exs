defmodule Rak.QueueTest do
  use RakTest.Case

  alias Rak.{
    Job,
    Queue
  }

  import Queue
  doctest Queue
end
