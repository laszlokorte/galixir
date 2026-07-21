defmodule Galixir.Algebras.PGA3 do
  @moduledoc """
  Three-dimensional Projective Geometric Algebra (PGA).

  This module implements Euclidean 3D projective geometry using:

      Cl(3,0,1)

  with signature:

      {1,1,1,0}

  and basis:

      e1, e2, e3, e0

  where `e0` is the ideal (infinite) basis vector.

  PGA represents geometric objects as homogeneous multivectors:

    * Points are grade-3 trivectors
    * Lines are grade-2 bivectors
    * Planes are grade-1 vectors

  Finite points are represented as:

      P = e123 + x*e032 + y*e013 + z*e021

  where the coefficient of `e123` is the homogeneous scale.

  Ideal points have zero `e123` coefficient and represent directions.

  ## Motors

  Euclidean transformations are represented by motors. This module supports:

    * translations
    * rotations around lines
    * motor transformations
    * interpolation through logarithm/exponential

  ## Examples

      iex> p = Galixir.Algebras.PGA3.point(1, 2, 3)
      iex> Galixir.Algebras.PGA3.point_coordinates(p)
      {1.0, 2.0, 3.0}

  """

  use Galixir.GeometricAlgebra,
    signature: {1, 1, 1, 0},
    bases: {1, 2, 3, 0}

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
    point(0, 0, 0)
  end

  # ----------------
  # Points
  # ----------------

  @doc """
  Checks whether a point is ideal.

  An ideal point has no finite homogeneous component.
  """
  def ideal_point?(p) do
    homogeneous_grade(p) == 3 and
      coefficient(p, :e123) == 0
  end

  @doc """
  Checks whether a point is finite.

  A finite point has a non-zero homogeneous component.
  """
  def finite_point?(p) do
    homogeneous_grade(p) == 3 and
      coefficient(p, :e123) != 0
  end

  @doc """
  Creates a finite point.

  The homogeneous representation is:

      P = e123 + x*e032 + y*e013 + z*e021
  """
  def point(x, y, z, w \\ 1) do
    new(
      e123: w,
      e032: x,
      e013: y,
      e021: z
    )
  end

  @doc """
  Creates a Euclidean direction vector.
  """
  def vector(x, y, z) do
    new(
      e1: x,
      e2: y,
      e3: z
    )
  end

  @doc """
  Creates the line through two points.
  """
  def line(a, b) do
    join(a, b)
  end

  # ----------------
  # Planes
  # ----------------

  @doc """
  Creates a plane from coefficients.

  Represents:

      ax + by + cz + d = 0

  """
  def plane(a, b, c, d) do
    new(
      e1: a,
      e2: b,
      e3: c,
      e0: d
    )
  end

  @doc """
  Creates a plane from a normal vector and a point.
  """
  def plane_from_normal_point(n, p) do
    n = normalize(n)
    {x, y, z} = point_coordinates(p)

    a = coefficient(n, :e1)
    b = coefficient(n, :e2)
    c = coefficient(n, :e3)

    plane(
      a,
      b,
      c,
      -(a * x + b * y + c * z)
    )
  end

  @doc """
  Extracts the normal vector from a plane.
  """
  def plane_normal(p) do
    vector(
      coefficient(p, :e1),
      coefficient(p, :e2),
      coefficient(p, :e3)
    )
  end

  @doc """
  Returns the normalized plane normal.
  """
  def unit_plane_normal(p) do
    normalize(plane_normal(p))
  end

  # ----------------
  # Join / meet
  # ----------------

  @doc """
  Computes the join of two objects.

  The join produces the smallest object containing both inputs.

  Examples:

      point ∨ point -> line
      line ∨ point  -> plane
  """
  def join(a, b) do
    undual(wedge(dual(a), dual(b)))
  end

  @doc """
  Computes the meet of two objects.

  The meet is the outer product.

  Examples:

      plane ∧ plane -> line
      line ∧ line   -> point
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

  @doc """
  Checks whether two objects are parallel.

  This is true when their intersection is an ideal object.
  """
  def parallel?(a, b) do
    ideal?(meet(a, b))
  end

  @doc """
  Checks whether two objects intersect in a finite object.
  """
  def intersects?(a, b) do
    m = meet(a, b)

    not zero?(m) and not ideal?(m)
  end

  @doc """
  Checks whether an object lies entirely at infinity.
  """
  def ideal?(x) do
    zero?(wedge(x, new(e0: 1)))
  end

  @doc """
  Checks whether two homogeneous objects represent the same entity.
  """
  def coincident?(a, b) do
    homogeneous_grade(a) == homogeneous_grade(b) and
      zero?(sub(canonicalize(a), canonicalize(b)))
  end

  # ----------------
  # Directions
  # ----------------

  @doc """
  Returns the ideal point representing a line direction.
  """
  def ideal_direction(line) do
    meet(line, new(e0: 1))
  end

  @doc """
  Extracts a Euclidean direction vector from a line.
  """
  def direction_vector(line) do
    d = ideal_direction(line)

    vector(
      coefficient(d, :e230),
      coefficient(d, :e013),
      coefficient(d, :e120)
    )
  end

  @doc """
  Returns a normalized line direction vector.
  """
  def unit_direction_vector(line) do
    normalize(direction_vector(line))
  end

  # ----------------
  # Motors
  # ----------------

  @doc """
  Creates a translation motor from a vector.
  """
  def translator(v) do
    new(
      scalar: 1,
      e01: coefficient(v, :e1) / 2,
      e02: coefficient(v, :e2) / 2,
      e03: coefficient(v, :e3) / 2
    )
  end

  @doc """
  Creates a translation motor from coordinates.
  """
  def translator(x, y, z) do
    new(
      scalar: 1,
      e01: x / 2,
      e02: y / 2,
      e03: z / 2
    )
  end

  @doc """
  Creates a rotation motor around an axis line.

  The angle is specified in radians.
  """
  def rotor(line_axis, angle) do
    line_axis = normalize_line(line_axis)

    add(
      new(scalar: :math.cos(angle / 2)),
      scale(
        -:math.sin(angle / 2),
        line_axis
      )
    )
    |> normalize()
  end

  @doc """
  Normalizes a line motor axis.
  """
  def normalize_line(line) do
    d = ideal_direction(line)

    n =
      gp(d, reverse(d))
      |> scalar_part()
      |> :math.sqrt()

    scale(1 / n, line)
  end

  @doc """
  Applies a motor transformation to an object.
  """
  def transform(motor, object) do
    gp(gp(motor, object), inverse(motor))
  end

  @doc """
  Creates the ideal point representing a direction.
  """
  def ideal_point(x, y, z) do
    new(
      e032: x,
      e013: y,
      e021: z
    )
  end

  @doc """
  Returns Cartesian coordinates of a finite point.
  """
  def point_coordinates(p) do
    w = coefficient(p, :e123)

    {
      coefficient(p, :e032) / w,
      coefficient(p, :e013) / w,
      coefficient(p, :e021) / w
    }
  end

  @doc """
  Returns the vector from point `a` to point `b`.
  """
  def direction_between_points(a, b) do
    d = sub(b, a)

    vector(
      coefficient(d, :e230),
      coefficient(d, :e013),
      coefficient(d, :e120)
    )
  end

  @doc """
  Computes the Euclidean distance between two points.
  """
  def distance(a, b) do
    {ax, ay, az} = point_coordinates(a)
    {bx, by, bz} = point_coordinates(b)

    dx = ax - bx
    dy = ay - by
    dz = az - bz

    :math.sqrt(dx * dx + dy * dy + dz * dz)
  end

  @doc """
  Negates a multivector.
  """
  def negate(x) do
    scale(-1, x)
  end

  @doc """
  Returns the homogeneous grade of a multivector.

  Returns `nil` for mixed-grade multivectors.
  """
  def homogeneous_grade(x) do
    case grades(x) do
      [g] -> g
      _ -> nil
    end
  end

  @doc """
  Computes the scalar product.
  """
  def dot(a, b) do
    gp(a, b)
    |> scalar_part()
  end

  @doc """
  Computes the motor aligning corresponding point sets.

  Uses an iterative PGA look-at style construction.
  """
  def align(ps, qs) do
    # https://observablehq.com/@enkimute/glu-lookat-in-3d-pga
    initial_m = one = new(scalar: 1)
    initial_q = dual(new(scalar: 1))

    Enum.zip_reduce(ps, qs, {initial_m, initial_q}, fn p, q, {m, prev_q} ->
      p = prev_q |> join(transform(m, p)) |> normalize()
      new_q = prev_q |> join(q) |> normalize() |> blade_inverse()
      new_m = new_q |> gp(p) |> add(one) |> gp(m)
      {new_m, new_q}
    end)
    |> elem(0)
  end

  @doc """
  Computes the logarithm of a motor.
  """
  def motor_log(mot) do
    scale(grade(mot, 2), 1 / coefficient(mot, :scalar))
  end

  @doc """
  Computes the exponential of a bivector motor logarithm.
  """
  def motor_exp(bv) do
    bv2 = gp(bv, bv)
    bv4 = grade(bv2, 4)
    numerator = add(add(new(scalar: 1), bv), scale(bv4, 0.5))
    denominator = 1 - coefficient(bv2, :scalar)
    scale(numerator, 1 / denominator) |> normalize()
  end

  @doc """
  Raises a motor to a scalar power.

  Useful for motor interpolation.
  """
  def motor_pow(motor, t) do
    motor
    |> motor_log()
    |> scale(t)
    |> motor_exp()
  end
end
