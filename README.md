# Rak

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `rak` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rak, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/rak](https://hexdocs.pm/rak).

### Mnesia Setup

```elixir
config :mnesia,
  dir: 'mnesia/#{Mix.env()}/#{node()}'
```

Run the following mix task to create the Mnesia schema and required databases:

```bash
$ mix rak.setup
```

<br>

## Usage

```elixir
defmodule MyApp.Worker do
  use Rak.Worker

  def perform(arg) do
    # do something
  end
end
```

Enqueue a job to be processed by the worker:

```elixir
iex> Rak.enqueue(MyApp.Worker, :hello)
%Rak.Job{...}
```

### Concurrency

```elixir
defmodule MyApp.Worker do
  use Rak.Worker, concurrency: 5

  def perform(data) do
    MyApp.Service.perform(data)
  end
end
```

### Max Retries

```elixir
defmodule MyApp.Worker do
  use Rak.Worker, max_retries: 3

  def perform do
    raise "failed"
  end
end
```

Failing job retries 3 times:

```elixir
iex> job = Rak.enqueue(MyApp.Worker)
iex> ... delay determined by retry strategy
iex> job in Rak.jobs(:failed)
true
```

### Callbacks

```elixir
defmodule MyApp.Worker do
  use Rak.Worker

  def perform do
    # do something
  end

  def on_completed(%Rak.Job{} = job) do
    # do something when job is completed
    :ok
  end

  def on_failed(%Rak.Job{} = job, reason, stacktrace) do
    # do something when job failed
    :ok
  end
end
```

### Global Events

```elixir
defmodule MyApp.EventHandler do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(state) do
    :ok = Rak.subscribe()
    {:ok, state}
  end

  def handle_info({:completed, %Rak.Job{} = job}, state) do
    IO.inspect(job, label: "received `completed` event")
    {:noreply, state}
  end

  def handle_info({:failed, %Rak.Job{} = job}, state) do
    IO.inspect(job, label: "received `failed` event")
    {:noreply, state}
  end
end
```

Listen for events:

```elixir
iex> {:ok, pid} = MyApp.EventHandler.start_link()

iex> Rak.enqueue(MyApp.Worker, :ok)
%Rak.Job{...}
... job processed
received `completed` event: %Rak.Job{...}

iex> Rak.enqueue(MyApp.Worker, :error)
%Rak.Job{...}
... job processed
received `failed` event: %Rak.Job{...}
```

<br>
