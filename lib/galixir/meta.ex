defmodule Galixir.Meta do
  @type t :: %__MODULE__{}

  defstruct [
    :module,
    :dimensions,
    :size,
    :signature,
    :bases,
    :table,
    :blade_indices,
    :blade_aliases
  ]
end
