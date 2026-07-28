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

  ## Examples

      iex> point_coordinates(origin())
      {0.0, 0.0, 0.0}
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
    grade?(p, 3) and
      coefficient(p, :e123) == 0
  end

  @doc """
  Checks whether a point is finite.

  A finite point has a non-zero homogeneous component.
  """
  def finite_point?(p) do
    grade?(p, 3) and
      coefficient(p, :e123) != 0
  end

  @doc """
  Creates a finite point.

  The homogeneous representation is:

      P = e123 + x*e032 + y*e013 + z*e021


  ## Examples

      iex> point_coordinates(point(1, 2, 3))
      {1.0, 2.0, 3.0}

      iex> finite_point?(point(1, 2, 3))
      true

      iex> ideal_point?(ideal_point(1, 0, 0))
      true
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

  ## Examples

      iex> vector(1, 2, 3)
      new(e1: 1, e2: 2, e3: 3)
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

  ## Examples

      iex> a = point(0, 0, 0)
      iex> b = point(1, 0, 0)
      iex> l = line(a, b)
      iex> single_grade(l)
      2
  """
  def line(a, b) do
    join(a, b)
  end

  # ----------------
  # Planes
  # ----------------

  @doc """
  Creates a plane from coefficients.

  ## Examples

      iex> p = plane(0, 0, 1, 0)
      iex> plane_normal(p)
      new(e1: 0, e2: 0, e3: 1)
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

  ## Examples

    iex> p = plane_from_normal_point(vector(0, 0, 1), point(1, 2, 3))
    iex> contains?(p, point(10, -5, 3))
    true

    iex> p = plane_from_normal_point(vector(0, 0, 1), point(1, 2, 3))
    iex> contains?(p, point(10, -5, 4))
    false
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


  ## Examples

    iex> a = point(0, 0, 0)
    iex> b = point(1, 0, 0)
    iex> line = join(a, b)
    iex> single_grade(line)
    2
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

  ## Examples

      iex> p1 = plane(1, 0, 0, 0)
      iex> p2 = plane(0, 1, 0, 0)
      iex> l = meet(p1, p2)
      iex> single_grade(l)
      2
  """
  def meet(a, b) do
    wedge(a, b)
  end

  @doc """
  Tests whether two objects are incident.

  ## Examples

    iex> p = point(1, 2, 3)
    iex> l = line(point(0, 2, 3), point(5, 2, 3))
    iex> incident?(p, l)
    true
  """
  def incident?(a, b) do
    zero?(join(a, b))
  end

  @doc """
  Tests whether an object contains another object.

  ## Examples

    iex> p = plane(0, 0, 1, 0)
    iex> contains?(p, point(1, 2, 0))
    true

    iex> p = plane(0, 0, 1, 0)
    iex> contains?(p, point(1, 2, 3))
    false
  """
  def contains?(container, object) do
    zero?(join(container, object))
  end

  @doc """
  Checks whether two objects are parallel.

  ## Examples

      iex> l1 = line(point(0, 0, 0), point(1, 0, 0))
      iex> l2 = line(point(0, 1, 0), point(1, 1, 0))
      iex> parallel?(l1, l2)
      true
  """
  def parallel?(a, b) do
    ideal?(meet(a, b))
  end

  @doc """
  Checks whether two objects intersect in a finite object.

  ## Examples

    iex> p1 = plane_from_normal_point(vector(1, 1, 0), point(2, 0, 0))
    iex> p2 = plane_from_normal_point(vector(1, 0, 0), point(0, 0, 0))
    iex> intersects?(p1, p2)
    true

    iex> p1 = plane_from_normal_point(vector(1, 1, 0), point(1, 1, 0))
    iex> p2 = plane_from_normal_point(vector(1, 1, 0), point(0, 0, 0))
    iex> intersects?(p1, p2)
    false

    iex> p1 = plane_from_normal_point(vector(1, 0, 0), point(0, 1, 0))
    iex> p2 = plane_from_normal_point(vector(1, 0, 0), point(0, 0, 0))
    iex> intersects?(p1, p2)
    false
  """
  def intersects?(a, b) do
    m = meet(a, b)

    not zero?(m) and not ideal?(m)
  end

  @doc """
  Checks whether an object lies entirely at infinity.
  """
  def ideal?(x) do
    case single_grade(x) do
      3 -> ideal_point?(x)
      _ -> zero?(wedge(x, new(e0: 1)))
    end
  end

  @doc """
  Checks whether two homogeneous objects represent the same entity.
  ## Examples

    iex> a = point(1, 2, 3)
    iex> b = point(2, 4, 6, 2)
    iex> coincident?(a, b)
    true
  """
  def coincident?(a, b) do
    single_grade(a) == single_grade(b) and
      zero?(sub(canonicalize(a), canonicalize(b)))
  end

  # ----------------
  # Directions
  # ----------------

  @doc """
  Returns the ideal point representing a line direction.
  """
  def ideal_point_on_line(line) do
    meet(line, new(e0: 1))
  end

  @doc """
  Extracts a Euclidean direction vector from a line.

  ## Examples

    iex> l = line(point(0, 0, 0), point(0, 0, 1))
    iex> direction_vector(l)
    new(e3: 1)
  """
  def direction_vector(line) do
    d = ideal_point_on_line(line)

    vector(
      coefficient(d, :e023),
      coefficient(d, :e013),
      coefficient(d, :e021)
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
  ## Examples

    iex> t1 = translator(1, 0, 0)
    iex> t2 = translator(0, 2, 0)
    iex> p = transform(gp(t2, t1), origin())
    iex> point_coordinates(p)
    {1.0, 2.0, 0.0}
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
  Creates a translation motor.

  ## Examples

    iex> t = translator(1, 2, 3)
    iex> p = transform(t, origin())
    iex> point_coordinates(p)
    {1.0, 2.0, 3.0}
  """
  def translator(x, y, z) do
    new(
      scalar: 1,
      e01: -x / 2,
      e02: -y / 2,
      e03: -z / 2
    )
  end

  @doc """
  Creates a rotation motor around an axis.

  ## Examples

    iex> axis = line(point(0, 0, 0), point(0, 0, 1))
    iex> r = rotor(axis, :math.pi())
    iex> p = transform(r, point(1, 0, 0))
    iex> {x, y, z} = point_coordinates(p)
    iex> abs(x + 1.0) < 1.0e-10 and abs(y) < 1.0e-10 and abs(z) < 1.0e-10

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

  ## Examples

    iex> l = line(point(0, 0, 0), point(0, 0, 1))
    iex> n = normalize_line(l)
    iex> scalar_part(gp(n, n))
    -1.0
  """
  def normalize_line(line) do
    n =
      gp(line, reverse(line))
      |> scalar_part()
      |> abs()
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
      clean_zero(coefficient(p, :e032) / w),
      clean_zero(coefficient(p, :e013) / w),
      clean_zero(coefficient(p, :e021) / w)
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

  ## Examples

      iex> distance(point(0, 0, 0), point(3, 4, 0))
      5.0
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
  def single_grade(x) do
    case grades(x) do
      [g] -> g
      _ -> nil
    end
  end

  @doc """
  Computes the scalar product.
  """
  def scalar_product(a, b) do
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

  ## Examples

    iex> t = translator(10, 0, 0)
    iex> half = motor_pow(t, 0.5)
    iex> p = transform(half, origin())
    iex> point_coordinates(p)
    {5.0, 0.0, 0.0}
  """
  def motor_pow(motor, t) do
    motor
    |> motor_log()
    |> scale(t)
    |> motor_exp()
  end

  # handle IEEE-754 negative zero
  defp clean_zero(x) when x == 0.0, do: 0.0
  defp clean_zero(x), do: x
end
