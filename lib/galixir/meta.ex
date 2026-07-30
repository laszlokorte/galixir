defmodule Galixir.Meta do
  @moduledoc """
  Stores the compile-time metadata used to generate a geometric algebra module.
  """

  @type t :: %__MODULE__{}

  defstruct [
    :module,
    :dimensions,
    :metric,
    :bases,
    :table,
    :blade_indices,
    :blade_aliases,
    :epsilon
  ]
end
