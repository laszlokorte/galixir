defmodule Galixir.Algebras.PGA2 do
  @moduledoc """

  This module implements two-dimensional Euclidean geometry using the
  projective geometric algebra (PGA) model.

  Points, lines, and rigid-body transformations are encoded as multivectors,
  allowing geometric constructions to be expressed through algebraic
  operations such as the wedge product, meet, join, and sandwich product.

      Cl(2,0,1)

  with signature:

      {1,1,0} # e1*e1 = 1, e2*e2 = 1, e0*e0 = 0

  and basis:

      e1, e2, e0

  where `e0` is the ideal (infinite) basis vector.

  This module uses the dual representation of projective geometric algebra.
  In this representation, geometric objects are represented by their dual
  blades. In two-dimensional PGA this means:

    * Lines are represented as grade-1 vectors.
    * Points are represented as grade-2 bivectors.

  This duality is a property of the representation, not a change in the
  underlying geometry. In this representation, the join operation is
  implemented through dualization and the wedge product, while the meet
  operation uses the wedge product directly.

      join(a, b) = undual(wedge(dual(a), dual(b)))
      meet(a, b) = wedge(a, b)

  With this module's basis convention, finite points are represented as:

      P = e12 + x*e20 + y*e01

  where the coefficient of `e12` is the homogeneous scale factor.

  Ideal points have a zero `e12` component:

      P∞ = x*e20 + y*e01

  ## Examples

      iex> p = Galixir.Algebras.PGA2.point(2, 3)
      iex> Galixir.Algebras.PGA2.point_coordinates(p)
      {2.0, 3.0}

  """

  @epsilon 1.0e-10

  use Galixir.GeometricAlgebra,
    signature: {1, 1, 0},
    bases: {1, 2, 0}

  @doc """
  Returns the zero multivector.
  """
  def zero do
    new()
  end

  @doc """
  Returns the scalar identity element.
  """
  def one do
    new(scalar: 1)
  end

  @doc """
  Returns the Euclidean origin point.
  """
  def origin do
    point(0, 0)
  end

  # ----------------
  # Points
  # ----------------

  @doc """
  Creates a finite projective point.

  The point is represented homogeneously as:

      P = e12 + x*e20 + y*e01

  The optional `w` argument controls the homogeneous scale.
  Normally points should be created using the default value `1`.
  The homogeneous scale `w` must not be zero.

  ## Examples

      iex> point_coordinates(point(1, 2))
      {1.0, 2.0}

      iex> point_coordinates(point(1, 2, 2))
      {1.0, 2.0}

      iex> point_coordinates(point(1, 2, 0.5))
      {1.0, 2.0}

  """
  def point(x, y, w \\ 1) when w != 0 do
    new(
      e12: w,
      e20: x * w,
      e01: y * w
    )
  end

  @doc """
  Creates an ideal point representing a direction.

  Ideal points are points at infinity and have no finite location.

  Note that Euclidean vectors are not ideal points.
  Use `direction_point/1` to convert a line direction into an ideal point.
  """
  def ideal_point(x, y) do
    new(
      e20: x,
      e01: y
    )
  end

  @doc """
  Checks whether a PGA point is finite.

  A finite point has a non-zero homogeneous `e12` component.

  # Examples

  iex> finite_point?(point(1,2))
  true


  iex> finite_point?(ideal_point(1,2))
  false

  iex> finite_point?(vector(1,2))
  false

  """
  def finite_point?(p) do
    grade?(p, 2) and
      abs(coefficient(p, :e12)) >= @epsilon
  end

  @doc """
  Checks whether a PGA point is ideal.

  An ideal point has zero homogeneous `e12` component.

  ## Examples

      iex> ideal_point?(ideal_point(1,0))
      true

      iex> ideal_point?(point(1,0))
      false

      iex> ideal_point?(vector(1,0))
      false

  """
  def ideal_point?(p) do
    grade?(p, 2) and
      abs(coefficient(p, :e12)) < @epsilon
  end

  @doc """
  Extracts Cartesian coordinates from a finite point.

  Returns:

      {x, y}
  # Examples

  iex> point_coordinates(origin())
  {0.0, 0.0}


  iex> point_coordinates(point(2, 3))
  {2.0, 3.0}

  """
  def point_coordinates(p) do
    w = coefficient(p, :e12)

    if abs(w) < @epsilon do
      raise ArgumentError, "cannot extract Cartesian coordinates from a non-finite point"
    end

    {
      clean_zero(coefficient(p, :e20) / w),
      clean_zero(coefficient(p, :e01) / w)
    }
  end

  # ----------------
  # Vectors
  # ----------------

  @doc """
  Creates a Euclidean direction vector.
  """
  def vector(x, y) do
    new(
      e1: x,
      e2: y
    )
  end

  # ----------------
  # Lines
  # ----------------

  @doc """
  Creates a line from coefficients.

  Represents the equation:

      ax + by + c = 0

  as the PGA vector:

      a*e1 + b*e2 + c*e0

  The line is represented up to scale.

  iex> normalize(line(1,2,3)) == normalize(line(2,4,6))
  true

  """
  def line(a, b, c) do
    new(
      e1: a,
      e2: b,
      e0: c
    )
  end

  @doc """
  Creates the line through two points.

  Equivalent to:

    join(point1, point2)

  ## Examples

      iex> l = line(point(23, 42), point(3,4))
      iex> incident?(point(23,42), l)
      true
  """
  def line(a, b) do
    join(a, b)
  end

  @doc """
  Returns the normal vector of a line.

  The normal is:

      a*e1 + b*e2
  """
  def line_normal(l) do
    vector(
      coefficient(l, :e1),
      coefficient(l, :e2)
    )
  end

  @doc """
  Returns the normalized line normal vector.
  """
  def normalized_line_normal(l) do
    normalize(line_normal(l))
  end

  @doc """
  Creates a line from a normal vector and a point.
  """
  def line_from_normal_point(n, p) do
    n = normalize(n)
    {x, y} = point_coordinates(p)

    a = coefficient(n, :e1)
    b = coefficient(n, :e2)

    line(
      a,
      b,
      -(a * x + b * y)
    )
  end

  # ----------------
  # Join / meet
  # ----------------

  @doc """
  Computes the join of two geometric objects.

  The join returns the smallest blade containing both geometric objects.

  It is implemented using the dual outer product:

      a ∨ b = dual(dual(a) ∧ dual(b))

  In PGA, common cases are:

      point ∨ point -> line
      point ∨ line -> top-grade element (pseudoscalar, ie. trivector)

  In this dual representation, incidence is tested by the vanishing of the join.

  ## Examples

      iex> p1 = point(0, 0)
      iex> p2 = point(1, 0)
      iex> incident?(p1, line(p1, p2))
      true
  """
  def join(a, b) do
    undual(wedge(dual(a), dual(b)))
  end

  @doc """
  Computes the meet of two geometric objects.

  The meet returns the intersection of geometric objects. In this PGA
  representation it is computed using the outer product:

      a ∧ b

  Common case:

    line ∧ line -> point

  For non-intersecting objects, the result may be an ideal object or zero,
  depending on the geometric configuration.

  ## Examples

      iex> l1 = line(point(0, 0), point(1, 0))
      iex> l2 = line(point(0, 0), point(0, 1))
      iex> p = meet(l1, l2)
      iex> point_coordinates(p)
      {0.0, 0.0}
  """
  def meet(a, b) do
    wedge(a, b)
  end

  @doc """
  Tests whether two objects are incident.

  In PGA, two objects are incident when their join vanishes.

  Note that identical objects are incident with themselves.
  Parallel distinct lines are not incident.

  `incident?/2` is not the same as geometric intersection.
  Parallel coincident lines are incident.

  This includes cases such as:
  - a point lying on a line
  - an ideal point representing the direction of a line
  - identical geometric objects


  ## Examples

      iex> incident?(point(0,0), line(0,1,0))
      true

      iex> p = point(1, 2)
      iex> l = line(point(1, 2), point(3, 4))
      iex> incident?(p, l)
      true

      iex> p = point(1, 2)
      iex> l = line(point(0, 0), point(1, 0))
      iex> incident?(p, l)
      false

      iex> l1 = line(point(0, 0), point(1, 0))
      iex> l2 = line(point(2, 0), point(3, 0))
      iex> incident?(l1, l2)
      true

      iex> incident?(point(0, 0), line(point(0, 0), point(1, 0)))
      true

      iex> incident?(point(0, 1), line(point(0, 0), point(1, 0)))
      false

      iex> incident?(ideal_point(1, 0), line(point(0, 0), point(1, 0)))
      true

      iex> p = ideal_point(1, 0)
      iex> l = line(point(0, 0), point(1, 0))
      iex> incident?(p, l)
      true

      iex> p = ideal_point(0, 1)
      iex> l = line(point(0, 0), point(1, 0))
      iex> incident?(p, l)
      false

  """
  def incident?(a, b) do
    zero?(join(a, b))
  end

  # ----------------
  # Directions
  # ----------------

  @doc """
  Returns the ideal point representing the direction of a line.

  The result is a point at infinity, not a Euclidean vector.
  """
  def direction_point(line) do
    # e0 is the line at infinity
    meet(line, new(e0: 1))
  end

  @doc """
  Extracts the Euclidean direction vector of a line.

  ## Examples

      iex> direction_vector(line(point(0,1), point(2,0)))
      new(e1: 2, e2: -1)

  """
  def direction_vector(line) do
    d = direction_point(line)

    vector(
      coefficient(d, :e20),
      coefficient(d, :e01)
    )
  end

  @doc """
  Returns the normalized direction vector of a line.
  """
  def normalized_direction_vector(line) do
    normalize(direction_vector(line))
  end

  # ----------------
  # Transformations
  # ----------------

  @doc """
  Creates a translation motor.

  Translates by the vector `(x,y)`.

  ## Examples

      iex> m = translator(3, 4)
      iex> point_coordinates(transform(m, origin()))
      {3.0, 4.0}


      iex> point_coordinates(transform(translator(3, 4), origin()))
      {3.0, 4.0}

      iex> point_coordinates(transform(translator(-2, 5), point(1, 2)))
      {-1.0, 7.0}

      iex> p = point(1, 2)
      iex> point_coordinates(transform(translator(0, 0), p))
      {1.0, 2.0}

      iex> m = translator(3,4)
      iex> point_coordinates(transform(inverse(m), transform(m, point(5,6))))
      {5.0,6.0}
  """
  def translator(x, y) do
    new(
      scalar: 1,
      e01: -x / 2,
      e02: -y / 2
    )
  end

  @doc """
  Creates a translation motor from a vector.

  ## Examples

      iex> m = translator(vector(3, 4))
      iex> point_coordinates(transform(m, origin()))
      {3.0, 4.0}
  """
  def translator(v) do
    translator(
      coefficient(v, :e1),
      coefficient(v, :e2)
    )
  end

  @doc """
  Creates a rotation motor around the origin.

  The angle is specified in radians.

  ## Examples

      iex> p = point(1,0)
      iex> {x, y} = point_coordinates(transform(rotor(:math.pi / 2), p))
      iex> {Float.round(x, 10), Float.round(y, 10)}
      {0.0, 1.0}

      iex> p = point(3,4)
      iex> {x,y} = point_coordinates(transform(rotor(-:math.pi/2),
      ...>   transform(rotor(:math.pi/2), p)))
      iex> {Float.round(x,10), Float.round(y,10)}
      {3.0,4.0}
  """
  def rotor(angle) do
    new(
      scalar: :math.cos(angle / 2),
      e12: -:math.sin(angle / 2)
    )
    |> normalize()
  end

  @doc """
  Applies a motor transformation.

  Uses the sandwich product:

      M X M⁻¹
  """
  def transform(motor, object) do
    gp(gp(motor, object), inverse(motor))
  end

  # ----------------
  # Utility
  # ----------------

  @doc """
  Computes Euclidean distance between two finite points.

  iex> distance(point(1,2), point(1,2))
  0.0

  iex> distance(point(-1,-1), point(2,3))
  5.0

  """
  def distance(a, b) do
    {ax, ay} = point_coordinates(a)
    {bx, by} = point_coordinates(b)

    dx = ax - bx
    dy = ay - by

    :math.sqrt(dx * dx + dy * dy)
  end

  @doc """
  Computes the scalar product of two multivectors.

  The result depends on the metric of the algebra.

  In PGA2, points are represented as bivectors:

      P = e12 + x*e20 + y*e01

  They are not null elements as conformal points are in conformal geometric algebra.
  The metric of PGA2 gives:

      scalar_product(P, P) = -1

  for normalized finite points.

  ## Examples

      iex> scalar_product(vector(1, 2), vector(3, 4))
      11.0

      iex> scalar_product(new(e1: 1), new(e1: 2))
      2.0

      iex> scalar_product(point(1, 2), point(1, 2))
      -1.0
  """
  def scalar_product(a, b) do
    inner(a, b)
    |> scalar_part()
  end

  # handle IEEE-754 negative zero
  defp clean_zero(x) when x == 0.0, do: 0.0
  defp clean_zero(x), do: x
end
