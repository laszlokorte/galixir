defmodule Galixir.Algebras.PGA4 do
  use Galixir.Algebras.Models.PGA, dimensions: {"x", "y", "z", "w"}

  @doc """
  Creates a 4D hyperplane `ax + by + cz + dw + e = 0` (grade 1) when
  `(a, b, c, d)` is nonzero. A zero normal gives the ideal hyperplane or zero.

      iex> incident?(hyperplane(0, 0, 0, 1, -4), point(1, 2, 3, 4))
      true
  """
  def hyperplane(a, b, c, d, e), do: new(e1: a, e2: b, e3: c, e4: d, e0: e)

  @doc """
  Creates a line through two distinct 4D points (grade 3). Coincident
  homogeneous points give the zero multivector instead of a unique line.

      iex> grade(line(point(0, 0, 0, 0), point(1, 0, 0, 0)))
      3
      iex> zero?(line(origin(), origin()))
      true
  """
  def line(a, b), do: join(a, b)

  @doc """
  Creates a plane through three independent, non-collinear 4D points
  (grade 2). Coincident or collinear points give a zero join instead of
  a unique plane.

      iex> grade(plane(point(0, 0, 0, 0), point(1, 0, 0, 0), point(0, 1, 0, 0)))
      2
      iex> zero?(plane(point(0, 0, 0, 0), point(1, 0, 0, 0), point(2, 0, 0, 0)))
      true
  """
  def plane(a, b, c), do: join(line(a, b), c)
end
