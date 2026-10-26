defmodule Galixir.Algebras.PGA2 do
  use Galixir.Algebras.Models.PGA, dimensions: {"x", "y"}

  @doc """
  Creates a point with nonzero homogeneous scale; zero scale is rejected in
  PGA2. Very small nonzero scales may still fall below the epsilon threshold
  used by `point_coordinates/1`.

      iex> point_coordinates(point(1, 2, 2))
      {1.0, 2.0}
  """
  def point(x, y, homogeneous_scale) when homogeneous_scale != 0,
    do: super(x, y, homogeneous_scale)

  @doc """
  Creates a line `ax + by + c = 0` (grade 1) when `(a, b)` is nonzero.
  If `a = b = 0`, this is an ideal hyperplane (or zero), not a finite line.

      iex> coincident?(line(1, 2, 3), line(2, 4, 6))
      true
  """
  def line(a, b, c), do: new(e1: a, e2: b, e0: c)

  @doc """
  Creates a line through two distinct points. Coincident homogeneous points
  give the zero multivector instead of a unique line.

      iex> incident?(point(1, 2), line(point(1, 2), point(3, 4)))
      true
      iex> zero?(line(point(1, 2), point(1, 2)))
      true
  """
  def line(a, b), do: join(a, b)

  @doc "Returns the Euclidean normal vector of a finite line (scaled with the line)."
  def line_normal(l), do: vector(coefficient(l, :e1), coefficient(l, :e2))

  @doc "Returns the normalized normal vector of a finite line; requires a nonzero normal."
  def normalized_line_normal(l), do: normalize!(line_normal(l))

  @doc "Creates a finite line from a nonzero Euclidean normal vector and a finite point."
  def line_from_normal_point(n, p) do
    n = normalize!(n)
    {x, y} = point_coordinates(p)
    a = coefficient(n, :e1)
    b = coefficient(n, :e2)
    line(a, b, -(a * x + b * y))
  end

  @doc """
  Returns the ideal point representing the direction of a finite line.
  For an ideal or zero line, the meet with `e0` vanishes.

      iex> ideal_point?(direction_point(line(point(0, 0), point(1, 0))))
      true
  """
  def direction_point(line), do: meet(line, new(e0: 1))

  @doc """
  Extracts the Euclidean direction vector of a finite line. Its magnitude
  depends on the line's homogeneous scale; ideal or zero lines give zero.

      iex> direction_vector(line(point(0, 1), point(2, 0)))
      new(e1: 2, e2: -1)
  """
  def direction_vector(line) do
    d = direction_point(line)
    vector(coefficient(d, :e20), coefficient(d, :e01))
  end

  @doc "Returns a normalized Euclidean direction of a finite line; requires a nonzero direction."
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
