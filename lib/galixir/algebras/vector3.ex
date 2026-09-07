defmodule Galixir.Algebras.Vector3 do
  use Galixir.Algebras.Kinds.Vector,
    dimensions: {"x", "y", "z"},
    docs: """
    ## Examples

        iex> cross(vector(1, 0, 0), vector(0, 1, 0)) |> coordinates()
        {0.0, 0.0, 1.0}
    """
end
