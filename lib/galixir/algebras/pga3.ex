defmodule Galixir.Algebras.PGA3 do
  @moduledoc """
  This module implements three-dimensional Euclidean geometry using the
  projective geometric algebra (PGA) model.

  Points, lines, planes, and rigid-body transformations are encoded as
  multivectors, allowing geometric constructions to be expressed through
  algebraic operations such as the wedge product, meet, join, and sandwich
  product.

      Cl(3,0,1)

  with metric:

      {1,1,1,0} # e1*e1 = 1, e2*e2 = 1, e3*e3 = 1, e0*e0 = 0

  and basis:

      e1, e2, e3, e0

  where `e0` is the ideal (infinite) basis vector.

  This module uses the dual representation of projective geometric algebra.
  In this representation, geometric objects are represented by their dual
  blades.

  This duality is a property of the representation, not a change in the
  underlying geometry. In the dual representation:

  * planes are vectors (1-blades)
  * lines are bivectors (2-blades)
  * points are trivectors (3-blades)

  These are projective objects and should not be confused with Euclidean direction vectors.

      join(a, b) = undual(wedge(dual(a), dual(b)))
      meet(a, b) = wedge(a, b)

  With this module's basis convention, finite points are represented as:

      P = e123 + x*e032 + y*e013 + z*e021

  where the coefficient of `e123` is the homogeneous scale factor.

  Ideal points have a zero `e123` component:

      P∞ = x*e032 + y*e013 + z*e021

  Ideal points represent directions and are points at infinity. They are
  distinct from Euclidean vectors, which are represented by grade-1 elements.

  ## Motors

  Euclidean rigid-body transformations are represented by motors.

  This module supports:

    * translations
    * rotations around lines
    * motor transformations using the sandwich product
    * interpolation through motor logarithms and exponentials

  A motor transformation is applied as:

      M X M⁻¹

  ## Examples

      iex> p = Galixir.Algebras.PGA3.point(1, 2, 3)
      iex> Galixir.Algebras.PGA3.point_coordinates(p)
      {1.0, 2.0, 3.0}

  """

  use Galixir.GeometricAlgebra,
    metric: {1, 1, 1, 0},
    bases: {"1", "2", "3", "0"}

  @doc """
  Returns the zero multivector.

  ## Examples

    iex> zero()
    new()
  """
  def zero do
    new()
  end

  @doc """
  Returns the scalar identity element.

  ## Examples

    iex> one()
    new(scalar: 1)
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

  ## Examples

    iex> ideal_point?(ideal_point(1,0,0))
    true

    iex> finite_point?(point(1,2,3))
    true
  """
  def ideal_point?(p) do
    grade?(p, 3) and
      abs(coefficient(canonicalize(p), :e123)) < epsilon()
  end

  @doc """
  Checks whether a point is finite.

  A finite point has a non-zero homogeneous component.

  ## Examples

    iex> finite_point?(point(1, 2, 3))
    true

    iex> finite_point?(ideal_point(1, 2, 3))
    false
  """
  def finite_point?(p) do
    grade?(p, 3) and
      abs(coefficient(canonicalize(p), :e123)) >= epsilon()
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
      e032: x * w,
      e013: y * w,
      e021: z * w
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
      iex> grade(l)
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
    iex> incident?(p, point(10, -5, 3))
    true

    iex> p = plane_from_normal_point(vector(0, 0, 1), point(1, 2, 3))
    iex> incident?(p, point(10, -5, 4))
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

  ## Examples

    iex> plane_normal(plane(1, 2, 3, 4))
    new(e1: 1, e2: 2, e3: 3)
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

  ## Examples

    iex> normalized_plane_normal(plane(0, 0, 5, 0))
    new(e3: 1.0)
  """
  def normalized_plane_normal(p) do
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
    iex> grade(line)
    2
  """
  def join(a, b) do
    undual(wedge(dual(a), dual(b)))
  end

  @doc """
  Computes the meet of two objects.

  The meet is the outer product.
  The meet operation does not imply that the result is a finite intersection.
  Parallel and skew objects may produce ideal elements or zero.

  Examples:

      plane ∧ plane -> line
      line ∧ line   -> point

  ## Examples

      iex> p1 = plane(1, 0, 0, 0)
      iex> p2 = plane(0, 1, 0, 0)
      iex> l = meet(p1, p2)
      iex> grade(l)
      2
  """
  def meet(a, b) do
    wedge(a, b)
  end

  @doc """
  Tests whether two geometric objects are incident.

  Two objects are incident when they share a common geometric element.
  In the dual representation this is equivalent to their join being the zero multivector.

  In this dual representation, incidence is tested using join.
  This is equivalent to the usual containment relation.

  ## Examples

      iex> p = point(1, 2, 3)
      iex> l = line(point(0, 2, 3), point(5, 2, 3))
      iex> incident?(p, l)
      true

      iex> p = plane(0, 0, 1, 0)
      iex> incident?(p, point(1, 2, 0))
      true

      iex> p = plane(0, 0, 1, 0)
      iex> incident?(p, point(1, 2, 3))
      false
  """
  def incident?(a, b) do
    zero?(join(a, b))
  end

  @doc """
  Checks whether a line is ideal.

  An ideal line contains only directions and has no finite location.

  ## Examples

      iex> finite = line(point(0, 0, 0), point(1, 0, 0))
      iex> ideal_line?(finite)
      false

      iex> offset = line(point(10, 5, 3), point(11, 5, 3))
      iex> ideal_line?(offset)
      false

      iex> ideal = line(ideal_point(1, 0, 0), ideal_point(0, 1, 0))
      iex> ideal_line?(ideal)
      true

      iex> ideal = line(ideal_point(1, 0, 0), ideal_point(0, 0, 1))
      iex> ideal_line?(ideal)
      true

      iex> ideal = line(ideal_point(1, 0, 0), ideal_point(1, 0, 0))
      iex> ideal_line?(ideal)
      false

      iex> zero?(line(ideal_point(1, 0, 0), ideal_point(1, 0, 0)))
      true
  """
  def ideal_line?(l) do
    grade?(l, 2) and
      zero?(wedge(l, new(e0: 1)))
  end

  @doc """
  Checks whether two homogeneous objects represent the same entity.

  ## Examples

    iex> a = point(1, 2, 3, 1)
    iex> b = point(1, 2, 3, 2)
    iex> coincident?(a, b)
    true
  """
  def coincident?(a, b) do
    grade(a) == grade(b) and
      zero?(sub(canonicalize(a), canonicalize(b)))
  end

  @doc """
  Checks whether two lines are parallel.

  Two lines are parallel when they have the same ideal point
  (direction), including the case where they are identical.

  ## Examples

      iex> a = line(point(0, 0, 0), point(1, 0, 0))
      iex> b = line(point(0, 1, 0), point(1, 1, 0))
      iex> parallel?(a, b)
      true

      iex> a = line(point(0, 0, 0), point(1, 0, 0))
      iex> b = line(point(0, 0, 0), point(0, 1, 0))
      iex> parallel?(a, b)
      false

      iex> a = line(point(0, 0, 0), point(1, 0, 0))
      iex> parallel?(a, a)
      true
  """
  def parallel?(line_a, line_b) do
    coincident?(direction_point(line_a), direction_point(line_b))
  end

  # ----------------
  # Directions
  # ----------------

  @doc """
  Returns the ideal point representing a line direction.

  ## Examples

    iex> l = line(point(0,0,0), point(1,0,0))
    iex> ideal_point?(direction_point(l))
    true
  """
  def direction_point(line) do
    meet(line, new(e0: 1))
  end

  @doc """
  Extracts a Euclidean direction vector from a line.

  ## Examples

    iex> l = line(point(1, 2, 3), point(2, 3, 4))
    iex> direction_vector(l)
    new(e1: 1, e2: 1, e3: 1)
  """
  def direction_vector(line) do
    d = direction_point(line)

    vector(
      coefficient(d, :e032),
      coefficient(d, :e013),
      coefficient(d, :e021)
    )
  end

  @doc """
  Returns a normalized line direction vector.

  ## Examples

    iex> l = line(point(0,0,0), point(0,0,5))
    iex> normalized_direction_vector(l)
    new(e3: 1.0)
  """
  def normalized_direction_vector(line) do
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
    iex> origin()
    ...> |> transform(gp(t2, t1))
    ...> |> point_coordinates()
    {1.0, 2.0, 0.0}
  """
  def translator(v) do
    translator(
      coefficient(v, :e1),
      coefficient(v, :e2),
      coefficient(v, :e3)
    )
  end

  @doc """
  Creates a translation motor.

  ## Examples

    iex> point_coordinates(transform(origin(), translator(1, 2, 3)))
    {1.0, 2.0, 3.0}

    iex> point_coordinates(transform(point(1, 2, 3), translator(-1, -2, -3)))
    {0.0, 0.0, 0.0}

    iex> p = point(4, 5, 6)
    iex> point_coordinates(transform(p, translator(1, 2, 3)))
    {5.0, 7.0, 9.0}

    iex> point_coordinates(transform(origin(), translator(vector(1, 2, 3))))
    {1.0, 2.0, 3.0}

    iex> v = vector(-3, 4, 5)
    iex> point_coordinates(transform(origin(), translator(v)))
    {-3.0, 4.0, 5.0}
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
    iex> {x, y, z} = point(1, 0, 0)
    ...> |> transform(r)
    ...> |> point_coordinates()
    iex> abs(x + 1.0) < 1.0e-10 and abs(y) < 1.0e-10 and abs(z) < 1.0e-10

    iex> axis = line(point(0, 0, 0), point(0, 0, 1))
    iex> {x, y, z} = point(1, 0, 0)
    ...> |> transform(rotor(axis, :math.pi() / 2))
    ...> |> point_coordinates()
    iex> {clean_zero(Float.round(x, 10)), clean_zero(Float.round(y, 10)), clean_zero(Float.round(z, 10))}
    {0.0, 1.0, 0.0}

    iex> axis = line(point(0, 0, 0), point(1, 0, 0))
    iex> {x, y, z} = point(0, 1, 0)
    ...> |> transform(rotor(axis, :math.pi() / 2))
    ...> |> point_coordinates()
    iex> {clean_zero(Float.round(x, 10)), clean_zero(Float.round(y, 10)), clean_zero(Float.round(z, 10))}
    {0.0, 0.0, 1.0}

    iex> axis = line(point(0, 0, 0), point(0, 1, 0))
    iex> {x, y, z} = point(1, 0, 0)
    ...> |> transform(rotor(axis, :math.pi()))
    ...> |> point_coordinates()
    iex> {clean_zero(Float.round(x, 10)), clean_zero(Float.round(y, 10)), clean_zero(Float.round(z, 10))}
    {-1.0, 0.0, 0.0}

    iex> axis = line(point(0, 0, 0), point(0, 0, 1))
    iex> r = rotor(axis, :math.pi() / 3)
    iex> point(2, 3, 4)
    ...> |> transform(r)
    ...> |> transform(inverse(r))
    ...> |> point_coordinates()
    {2.0, 3.0, 4.0}

  """
  def rotor(line_axis, angle) do
    line_axis = normalize_line(line_axis)

    add(
      new(scalar: :math.cos(angle / 2)),
      scale(
        :math.sin(angle / 2),
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

    if n < epsilon() do
      raise ArgumentError, "cannot normalize null line"
    end

    scale(1 / n, line)
  end

  @doc """
  Applies a motor transformation to an object.

  ## Examples

    iex> origin()
    ...> |> transform(translator(1, 2, 3))
    ...> |> point_coordinates()
    {1.0, 2.0, 3.0}

    iex> m = translator(3, 4, 5)
    iex> origin()
    ...> |> transform(m)
    ...> |> point_coordinates()
    {3.0, 4.0, 5.0}

    iex> m = translator(3, 4, 5)
    iex> point(1, 2, 3)
    ...> |> transform(m)
    ...> |> transform(inverse(m))
    ...> |> point_coordinates()
    {1.0, 2.0, 3.0}

    iex> m = gp(translator(1, 0, 0), translator(0, 2, 0))
    iex> origin()
    ...> |> transform(m)
    ...> |> point_coordinates()
    {1.0, 2.0, 0.0}
  """
  def transform(object, motor) do
    # Motors are normalized, therefore reverse == inverse
    gp(gp(motor, object), reverse(motor))
  end

  @doc """
  Creates the ideal point representing a direction.

  Do not use ideal points as direction vectors.
  Use `vector/3` when a Euclidean vector is required.

  ## Examples

    iex> ideal_point(1,2,3)
    new(e032: 1, e013: 2, e021: 3)
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

  ## Examples

    iex> point_coordinates(point(4,5,6))
    {4.0, 5.0, 6.0}
  """
  def point_coordinates(p) do
    w = coefficient(p, :e123)

    if abs(w) < epsilon() do
      raise ArgumentError,
            "cannot extract Cartesian coordinates from a non-finite point"
    end

    {
      clean_zero(coefficient(p, :e032) / w),
      clean_zero(coefficient(p, :e013) / w),
      clean_zero(coefficient(p, :e021) / w)
    }
  end

  @doc """
  Returns the vector from point `a` to point `b`.

  ## Examples

    iex> direction_between_points(point(1,2,3), point(4,6,8))
    new(e1: 3, e2: 4, e3: 5)
  """
  def direction_between_points(a, b) do
    d = sub(b, a)

    vector(
      coefficient(d, :e032),
      coefficient(d, :e013),
      coefficient(d, :e021)
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

  ## Examples

    iex> negate(vector(1,2,3)).data
    new(e1: -1, e2: -2, e3: -3).data
  """
  def negate(x) do
    scale(-1.0, x)
  end

  @doc """
  Computes the scalar product.

  ## Examples

    iex> scalar_product(vector(1,2,3), vector(4,5,6))
    32.0
  """
  def scalar_product(a, b) do
    inner(a, b)
    |> scalar_part()
  end

  @doc """
  Computes the motor aligning corresponding geometric objects.

  The constraints can be finite points or ideal points (directions).
  Each pair contributes a positional or rotational constraint.

  Lines and planes are not directly supported; represent them using
  their defining points and directions.

  The returned motor transforms the objects in the first list
  onto the corresponding objects in the second list.

  An empty set of constraints returns the identity motor.

  Uses an [iterative PGA look-at style construction](https://observablehq.com/@enkimute/glu-lookat-in-3d-pga).

  ## Examples

    iex> align([], []) == one()
    true

    iex> m = align([point(0,0,0)], [point(1,2,3)])
    iex> point(0, 0, 0)
    ...> |> transform(m)
    ...> |> point_coordinates()
    {1.0, 2.0, 3.0}

    iex> from = [
    ...>   point(0, 0, 0),
    ...>   point(1, 0, 0)
    ...> ]
    iex> to = [
    ...>   point(0, 0, 0),
    ...>   point(0, 1, 0)
    ...> ]
    iex> m = align(from, to)
    iex> point(1, 0, 0)
    ...> |> transform(m)
    ...> |> point_coordinates()
    {0.0, 1.0, 0.0}

    iex> from = [
    ...>   point(0, 0, 0),
    ...>   point(1, 0, 0),
    ...>   point(0, 1, 0)
    ...> ]
    iex> to = [
    ...>   point(1, 2, 3),
    ...>   point(1, 3, 3),
    ...>   point(0, 2, 3)
    ...> ]
    iex> m = align(from, to)
    iex> point_coordinates(transform(point(1, 0, 0), m))
    {1.0, 3.0, 3.0}

    iex> p = point(1, 2, 3)
    iex> m = align([p], [p])
    iex> point_coordinates(transform(p, m))
    {1.0, 2.0, 3.0}


    iex> from = [
    ...>   point(0, 0, 0),
    ...>   point(1, 0, 0)
    ...> ]
    iex> to = [
    ...>   point(3, 4, 5),
    ...>   point(3, 5, 5)
    ...> ]
    iex> m = align(from, to)
    iex> inv = inverse(m)
    iex> point_coordinates(transform(transform(point(7, 8, 9), m), inv))
    {7.0, 8.0, 9.0}

    iex> align([point(0, 0, 0)], [])
    ** (ArgumentError) cannot align different numbers of objects
  """
  def align([], []), do: one()

  def align(as, bs) when length(as) != length(bs) do
    raise ArgumentError, "cannot align different numbers of objects"
  end

  def align(ps, qs) do
    # https://observablehq.com/@enkimute/glu-lookat-in-3d-pga
    initial_m = identity = one()
    initial_q = dual(new(scalar: 1))

    Enum.zip_reduce(ps, qs, {initial_m, initial_q}, fn p, q, {m, prev_q} ->
      p = prev_q |> join(transform(p, m)) |> normalize()
      new_q = prev_q |> join(q) |> normalize() |> blade_inverse()
      new_m = new_q |> gp(p) |> add(identity) |> gp(m)
      {new_m, new_q}
    end)
    |> elem(0)
  end

  @doc """
  Computes the logarithm of a motor.

  ## Examples

    iex> t = translator(10,0,0)
    iex> motor_exp(motor_log(t)) |> normalize() == normalize(t)
    true
  """
  def motor_log(mot) do
    scale(grade(mot, 2), 1 / coefficient(mot, :scalar))
  end

  @doc """
  Computes the exponential of a bivector motor logarithm.

  ## Examples

    iex> b = motor_log(translator(5,0,0))
    iex> motor_exp(b) |> normalize() == normalize(translator(5,0,0))
    true
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
    iex> p = transform(origin(), half)
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
