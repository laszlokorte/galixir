defmodule Galixir.Algebras.PGA2 do
  @moduledoc """
  Two-dimensional Projective Geometric Algebra (PGA).

  This module implements the projective geometry of the Euclidean plane
  using the degenerate Clifford algebra:

      Cl(2,0,1)

  with signature:

      {1,1,0}

  and basis:

      e1, e2, e0

  where `e0` is the ideal (infinite) basis vector.

  In PGA, geometric entities are represented homogeneously:

    * Points are grade-2 bivectors
    * Lines are grade-1 vectors
    * Directions are ideal points

  Finite points are represented as:

      P = e12 + x*e20 + y*e01

  where the coefficient of `e12` is the homogeneous scale factor.

  Ideal points have no finite component:

      P∞ = x*e20 + y*e01

  ## Examples

      iex> p = Galixir.Algebras.PGA2.point(2, 3)
      iex> Galixir.Algebras.PGA2.point_coordinates(p)
      {2.0, 3.0}

  """

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

  """
  def point(x, y, w \\ 1) do
    new(
      e12: w,
      e20: x,
      e01: y
    )
  end

  @doc """
  Creates an ideal point representing a direction at infinity.

  Ideal points have no finite position and are used to represent
  directions and points at infinity.
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
  """
  def finite_point?(p) do
    homogeneous_grade(p) == 2 and
      coefficient(p, :e12) != 0
  end

  @doc """
  Checks whether a PGA point is ideal.

  An ideal point has zero homogeneous `e12` component.
  """
  def ideal_point?(p) do
    homogeneous_grade(p) == 2 and
      coefficient(p, :e12) == 0
  end

  @doc """
  Extracts Cartesian coordinates from a finite point.

  Returns:

      {x, y}

  """
  def point_coordinates(p) do
    w = coefficient(p, :e12)

    {
      coefficient(p, :e20) / w,
      coefficient(p, :e01) / w
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
  def unit_line_normal(l) do
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
  Computes the join of two objects.

  In PGA this produces the smallest object containing both inputs.

  Examples:

      point ∨ point -> line
      point ∨ line  -> plane element

  """
  def join(a, b) do
    undual(wedge(dual(a), dual(b)))
  end

  @doc """
  Computes the meet of two objects.

  In PGA the meet is the outer product.

  Examples:

      line ∧ line -> point
  """
  def meet(a, b) do
    wedge(a, b)
  end

  @doc """
  Tests whether two objects are incident.
  """
  def incident?(a, b) do
    zero?(join(a, b))
  end

  @doc """
  Tests whether an object contains another object.
  """
  def contains?(container, object) do
    zero?(join(container, object))
  end

  # ----------------
  # Directions
  # ----------------

  @doc """
  Returns the ideal point representing the direction of a line.
  """
  def ideal_direction(line) do
    meet(line, new(e0: 1))
  end

  @doc """
  Extracts the Euclidean direction vector of a line.
  """
  def direction_vector(line) do
    d = ideal_direction(line)

    vector(
      coefficient(d, :e20),
      coefficient(d, :e01)
    )
  end

  @doc """
  Returns the normalized direction vector of a line.
  """
  def unit_direction_vector(line) do
    normalize(direction_vector(line))
  end

  # ----------------
  # Transformations
  # ----------------

  @doc """
  Creates a translation motor.

  Translates by the vector `(x,y)`.
  """
  def translator(x, y) do
    new(
      scalar: 1,
      e01: x / 2,
      e02: y / 2
    )
  end

  @doc """
  Creates a translation motor from a vector.
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
  Negates a multivector.
  """
  def negate(x) do
    scale(-1, x)
  end

  @doc """
  Computes Euclidean distance between two finite points.
  """
  def distance(a, b) do
    {ax, ay} = point_coordinates(a)
    {bx, by} = point_coordinates(b)

    dx = ax - bx
    dy = ay - by

    :math.sqrt(dx * dx + dy * dy)
  end

  @doc """
  Returns the grade if the multivector has a single grade.

  Returns `nil` for mixed-grade multivectors.
  """
  def homogeneous_grade(x) do
    case grades(x) do
      [g] -> g
      _ -> nil
    end
  end

  @doc """
  Computes the scalar product of two multivectors.
  """
  def dot(a, b) do
    gp(a, b)
    |> scalar_part()
  end
end
