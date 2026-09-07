defmodule Galixir.Algebras.Vector3 do
  use Galixir.Algebras.Kinds.Vector,
    dimensions: {"x", "y", "z"},
    docs: """
    ## Examples

        iex> cross(vector(1, 0, 0), vector(0, 1, 0)) |> coordinates()
        {0.0, 0.0, 1.0}
    """

  @doc """
  Computes the vector cross product of two vectors.

  It is the negative pseudoscalar dual of the outer product:

      a × b = -(a ∧ b) * e123

  ## Examples

      iex> cross(vector(1, 2, 3), vector(-3, 2, 1))
      vector(-4, -10, 8)
  """
  def cross(a, b), do: negate(gp(wedge(a, b), pseudoscalar()))
end
