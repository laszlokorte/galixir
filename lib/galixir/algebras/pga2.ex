defmodule Galixir.Algebras.PGA2 do
  use Galixir.Algebras.Models.PGA, dimensions: {"x", "y"}

  @doc """
  Creates a finite point with nonzero homogeneous scale. Zero scale is
  rejected in PGA2.

      iex> point_coordinates(point(1, 2, 2))
      {1.0, 2.0}
  """
  def point(x, y, homogeneous_scale) when homogeneous_scale != 0,
    do: super(x, y, homogeneous_scale)

  @doc """
  Creates a line `ax + by + c = 0` (a grade-1 blade).

      iex> coincident?(line(1, 2, 3), line(2, 4, 6))
      true
  """
  def line(a, b, c), do: new(e1: a, e2: b, e0: c)

  @doc """
  Creates a line through two points.

      iex> incident?(point(1, 2), line(point(1, 2), point(3, 4)))
      true
  """
  def line(a, b), do: join(a, b)

  @doc "Returns the Euclidean normal vector of a line."
  def line_normal(l), do: vector(coefficient(l, :e1), coefficient(l, :e2))

  @doc "Returns the normalized normal vector of a line."
  def normalized_line_normal(l), do: normalize!(line_normal(l))

  @doc "Creates a line from a Euclidean normal vector and a finite point."
  def line_from_normal_point(n, p) do
    n = normalize!(n)
    {x, y} = point_coordinates(p)
    a = coefficient(n, :e1)
    b = coefficient(n, :e2)
    line(a, b, -(a * x + b * y))
  end

  @doc """
  Returns the ideal point representing a line direction.

      iex> ideal_point?(direction_point(line(point(0, 0), point(1, 0))))
      true
  """
  def direction_point(line), do: meet(line, new(e0: 1))

  @doc """
  Extracts the Euclidean direction vector of a line.

      iex> direction_vector(line(point(0, 1), point(2, 0)))
      new(e1: 2, e2: -1)
  """
  def direction_vector(line) do
    d = direction_point(line)
    vector(coefficient(d, :e20), coefficient(d, :e01))
  end

  @doc "Returns a normalized Euclidean line direction vector."
  def normalized_direction_vector(line), do: normalize!(direction_vector(line))

  @doc """
  Creates a rotation motor about the origin, with angle in radians.

      iex> {x, y} = point_coordinates(transform(point(1, 0), rotor(:math.pi() / 2)))
      iex> {Float.round(x, 10), Float.round(y, 10)}
      {0.0, 1.0}
  """
  def rotor(angle) do
    new(scalar: :math.cos(angle / 2), e12: -:math.sin(angle / 2))
    |> normalize!()
  end
end
