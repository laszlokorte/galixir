defmodule Galixir.Algebras.PGA4 do
  use Galixir.Algebras.Models.PGA, dimensions: {"x", "y", "z", "w"}

  @doc """
  Creates a 4D hyperplane `ax + by + cz + dw + e = 0` (grade 1).

      iex> incident?(hyperplane(0, 0, 0, 1, -4), point(1, 2, 3, 4))
      true
  """
  def hyperplane(a, b, c, d, e), do: new(e1: a, e2: b, e3: c, e4: d, e0: e)

  @doc """
  Creates a line through two 4D points (grade 3).

      iex> grade(line(point(0, 0, 0, 0), point(1, 0, 0, 0)))
      3
  """
  def line(a, b), do: join(a, b)

  @doc """
  Creates a plane through three 4D points (grade 2).

      iex> grade(plane(point(0, 0, 0, 0), point(1, 0, 0, 0), point(0, 1, 0, 0)))
      2
  """
  def plane(a, b, c), do: join(line(a, b), c)
end
