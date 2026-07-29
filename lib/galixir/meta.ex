defmodule Galixir.Meta do
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
