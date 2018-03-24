defmodule Rak.Util.Accessor do
  @moduledoc """
  Rak Util Accessor
  """
  defmacro __using__(_) do
    quote do
      require Rak.Util.Accessor
      import Rak.Util.Accessor
    end
  end

  @spec enum(key :: atom(), values :: list()) :: tuple()
  defmacro enum(key, values) do
    quote do
      @spec unquote(key)(value :: any()) :: boolean()
      def unquote(key)(value), do: value in unquote(values)
    end
  end

  @spec accessor(key :: atom(), type :: atom(), values :: list()) :: tuple()
  defmacro accessor(key, type, values \\ []) do
    quote do
      @spec unquote(key)(struct :: %__MODULE__{}, value :: any()) :: %__MODULE__{}
      def unquote(key)(%__MODULE__{} = struct, value) do
        guard!(unquote(key), value, unquote(type))

        if Enum.count(unquote(values)) > 0 do
          guard_in!(unquote(key), value, unquote(values))
        end

        %__MODULE__{struct | unquote(key) => value}
      end
    end
  end

  @spec raise_error(key :: atom(), value :: any()) :: no_return()
  defmacro raise_error(key, value) do
    quote do
      raise(ArgumentError, "Invalid value for `#{unquote(key)}`: #{inspect(unquote(value))}")
    end
  end

  @spec guard_in!(key :: atom(), value :: any(), values :: list()) :: true | no_return()
  def guard_in!(key, value, values), do: value in values || raise_error(key, value)

  @spec guard!(key :: atom(), value :: any(), type :: atom()) :: true | no_return()
  def guard!(key, value, :reason), do: is_nil(value) || guard!(key, value, :binary)
  def guard!(key, value, :integer), do: is_integer(value) || raise_error(key, value)
  def guard!(key, value, :binary), do: is_binary(value) || raise_error(key, value)
  def guard!(key, value, :atom), do: is_atom(value) || raise_error(key, value)
  def guard!(_, _, _), do: true
end
