defmodule Galixir.Algebras.CGA3 do
  @moduledoc """
  Three-dimensional Conformal Geometric Algebra (CGA).

  This module implements CGA for Euclidean 3-space using the metric:

      {1, 1, 1, 1, -1}

  with basis:

      e1, e2, e3, ep, em

  The Euclidean basis vectors represent ordinary 3D coordinates.
  The additional conformal basis vectors are combined into the null vectors:

      e_o   = (ep + em) / 2
      e_inf = em - ep

  Here `e_o` uses the letter `o` for *origin*; it is not the basis vector
  `e0` (e-subscript zero).

  Points are embedded into conformal space using:

      P(x,y,z) =
        e_o
        + x*e1
        + y*e2
        + z*e3
        + 1/2(x²+y²+z²)e_inf

  Lines, planes, and point-defined spheres use outer-product null-space
  (OPNS) representations. The center-and-radius form of `sphere/2` is an
  inner-product null-space (IPNS) representation.

  ## Examples

      iex> p = Galixir.Algebras.CGA3.point(1, 2, 3)
      iex> Galixir.Algebras.CGA3.point_coordinates(p)
      {1.0, 2.0, 3.0}
  """

  use Galixir.GeometricAlgebra,
    metric: {1, 1, 1, 1, -1},
    bases: {"1", "2", "3", "p", "m"}

  @doc """
  Returns the zero multivector.

  ## Examples

      iex> zero()
      ~G"0"
  """
  def zero do
    new()
  end

  @doc """
  Returns the scalar identity element.

  This is the multiplicative identity.

  ## Examples

      iex> gp(one(), new(e1: 2))
      new(e1: 2)
  """
  def one do
    new(scalar: 1)
  end

  @doc """
  Returns the conformal origin vector, `e_o` (e-subscript letter `o`).

  The origin is defined as `e_o = (ep + em) / 2` and satisfies
  `e_o · e_inf = -1`.

  ## Examples

      iex> scalar_product(e_o(), e_inf())
      -1.0
  """
  def e_o,
    do:
      scale(
        0.5,
        add(
          new(em: 1),
          new(ep: 1)
        )
      )

  @doc """
  Returns the conformal infinity vector.

  It is the null vector `e_inf = em - ep` and represents the direction of
  points at infinity.

  ## Examples

      iex> scalar_product(e_inf(), e_inf())
      0.0
  """
  def e_inf,
    do:
      sub(
        new(em: 1),
        new(ep: 1)
      )

  @doc """
  Creates a Euclidean vector.

  This creates only the Euclidean part:

      x*e1 + y*e2 + z*e3

  Use `point/3` to create a conformal point.

  ## Examples

      iex> point?(vector(1, 2, 3))
      false
  """
  def vector(x, y, z) do
    new(
      e1: x,
      e2: y,
      e3: z
    )
  end

  @doc """
  Embeds a Euclidean point into conformal space.

  Uses the standard CGA point embedding:

      P = e_o + x*e1 + y*e2 + z*e3
          + 1/2(x²+y²+z²)e_inf

  ## Examples

      iex> point_coordinates(point(1, 2, 3))
      {1.0, 2.0, 3.0}
  """
  def point(x, y, z) do
    add(
      add(
        e_o(),
        vector(x, y, z)
      ),
      scale(
        0.5 * (x * x + y * y + z * z),
        e_inf()
      )
    )
  end

  @doc """
  Returns the conformal representation of the Euclidean origin.

  ## Examples

      iex> point_coordinates(origin())
      {0.0, 0.0, 0.0}
  """
  def origin do
    point(0, 0, 0)
  end

  @doc """
  Extracts Euclidean coordinates from a conformal point.

  Returns:

      {x, y, z}

  The point may be scaled by any non-zero scalar.

  Raises `ArgumentError` for a point at infinity.

  ## Examples

      iex> point(2, 3, 4) |> scale(7) |> point_coordinates()
      {2.0, 3.0, 4.0}

      iex> point_coordinates(e_inf())
      ** (ArgumentError) cannot extract coordinates from point at infinity
  """
  def point_coordinates(p) do
    w = -scalar_product(p, e_inf())

    if abs(w) < epsilon() do
      raise ArgumentError, "cannot extract coordinates from point at infinity"
    end

    {
      clean_zero(scalar_product(p, new(e1: 1)) / w),
      clean_zero(scalar_product(p, new(e2: 1)) / w),
      clean_zero(scalar_product(p, new(e3: 1)) / w)
    }
  end

  @doc """
  Creates a line through two conformal points.

  The line is represented by:

      L = a ∧ b ∧ e_inf

  ## Examples

      iex> l = line(point(0, 0, 0), point(1, 0, 0))
      iex> contains?(l, point(2, 0, 0))
      true
      iex> contains?(l, point(0, 1, 0))
      false
  """
  def line(a, b) do
    wedge(
      wedge(a, b),
      e_inf()
    )
  end

  @doc """
  Creates a plane through three conformal points.

  The plane is represented by:

      Π = a ∧ b ∧ c ∧ e_inf

  ## Examples

      iex> p = plane(point(0, 0, 0), point(1, 0, 0), point(0, 1, 0))
      iex> contains?(p, point(2, 3, 0))
      true
      iex> contains?(p, point(0, 0, 1))
      false
  """
  def plane(a, b, c) do
    wedge(
      wedge(
        wedge(a, b),
        c
      ),
      e_inf()
    )
  end

  @doc """
  Creates a sphere through four conformal points.

  The resulting multivector represents the unique sphere containing
  the four points.

  ## Examples

      iex> s = sphere(point(1, 0, 0), point(-1, 0, 0), point(0, 1, 0), point(0, 0, 1))
      iex> contains?(s, point(0, -1, 0))
      true
  """
  def sphere(a, b, c, d) do
    wedge(
      wedge(
        wedge(a, b),
        c
      ),
      d
    )
  end

  @doc """
  Creates a sphere from a center point and radius.

  The radius is encoded using the infinity vector term. Unlike `sphere/4`,
  this returns the sphere's IPNS vector representation.

  ## Examples

      iex> s = sphere(point(1, 2, 3), 2)
      iex> contains?(s, point(3, 2, 3))
      true
      iex> contains?(s, point(4, 2, 3))
      false
  """
  def sphere(center, radius) do
    sub(
      center,
      scale(
        0.5 * radius * radius,
        e_inf()
      )
    )
  end

  @doc """
  Computes the meet (intersection) of two CGA objects.

  The meet is implemented through duality:

      meet(a,b) = dual(dual(a) ∧ dual(b))

  ## Examples

      iex> x_axis = line(point(-1, 0, 0), point(1, 0, 0))
      iex> yz_plane = plane(point(0, 0, 0), point(0, 1, 0), point(0, 0, 1))
      iex> contains?(meet(x_axis, yz_plane), origin())
      true
  """
  def meet(a, b) do
    dual(
      wedge(
        dual(a),
        dual(b)
      )
    )
  end

  @doc """
  Computes the join of two CGA objects.

  The join is the outer product:

      join(a,b) = a ∧ b

  The operands must use compatible representations. In particular, joining
  conformal points creates an OPNS point pair, not a line; use `line/2` to
  include `e_inf`.

  ## Examples

      iex> join(point(0, 0, 0), point(1, 0, 0)) |> grades()
      [2]
  """
  def join(a, b) do
    wedge(a, b)
  end

  @doc """
  Tests whether a conformal point lies on an object.

  Lines, planes, and point-defined spheres use their OPNS representation, so
  incidence is tested with the outer product. A center-and-radius sphere uses
  its IPNS vector representation, so incidence is tested with the scalar
  product.

  ## Examples

      iex> contains?(sphere(origin(), 1), point(1, 0, 0))
      true

      iex> contains?(line(point(0, 0, 0), point(1, 0, 0)), point(0, 1, 0))
      false
  """
  def contains?(object, point) do
    if grade?(object, 1) do
      abs(scalar_product(object, point)) < epsilon()
    else
      zero?(wedge(object, point))
    end
  end

  @doc """
  Creates a translator motor.

  The motor translates objects by the Euclidean displacement:

      {x,y,z}

  ## Examples

      iex> point(1, 2, 3) |> transform(translator(3, -1, 2)) |> point_coordinates()
      {4.0, 1.0, 5.0}
  """
  def translator(x, y, z) do
    t =
      add(
        one(),
        scale(
          -0.5,
          gp(
            vector(x, y, z),
            e_inf()
          )
        )
      )

    normalize(t)
  end

  @doc """
  Creates a translator motor from a Euclidean vector.

  ## Examples

      iex> translator(vector(1, 2, 3)) == translator(1, 2, 3)
      true
  """
  def translator(v) do
    translator(
      coefficient(v, :e1),
      coefficient(v, :e2),
      coefficient(v, :e3)
    )
  end

  @doc """
  Creates a rotor from a bivector and angle.

  The angle is measured in radians. The bivector determines the rotation
  plane and is normalized internally.

  ## Examples

      iex> {x, y, z} = point(1, 0, 0) |> transform(rotor(new(e12: 1), :math.pi() / 2)) |> cleanup() |> point_coordinates()
      iex> abs(x) < 1.0e-10 and abs(y - 1.0) < 1.0e-10 and z == 0.0
      true
  """
  def rotor(bivector, angle) do
    bivector = normalize(bivector)

    add(
      new(scalar: :math.cos(angle / 2)),
      scale(
        -:math.sin(angle / 2),
        bivector
      )
    )
  end

  @doc """
  Applies a motor transformation to a CGA object.

  Uses the sandwich product `M * X * reverse(M)`. Translation motors returned
  by `translator/3` and rotation motors returned by `rotor/2` can be supplied
  directly.

  ## Examples

      iex> point(1, 2, 3) |> transform(translator(3, -1, 2)) |> point_coordinates()
      {4.0, 1.0, 5.0}
  """
  def transform(object, motor) do
    gp(
      gp(motor, object),
      reverse(motor)
    )
  end

  @doc """
  Computes the scalar product of two multivectors.

  Returns the scalar part of their geometric product.

  ## Examples

      iex> scalar_product(new(e1: 1), new(e1: 1))
      1.0
  """
  def scalar_product(a, b) do
    scalar_part(gp(a, b))
  end

  @doc """
  Returns the CGA3 pseudoscalar:

      e1 ∧ e2 ∧ e3 ∧ ep ∧ em

  ## Examples

      iex> grades(pseudoscalar())
      [5]
  """
  def pseudoscalar do
    new(e123pm: 1)
  end

  @doc """
  Normalizes a conformal point to have conformal weight one.

  Finite conformal points satisfy `-p · e_inf = 1` after normalization.

  Raises `ArgumentError` if the point has zero weight.

  ## Examples

      iex> p = point(2, 3, 4) |> scale(5) |> normalize_point()
      iex> scalar_product(p, e_inf())
      -1.0
  """
  def normalize_point(p) do
    w = -scalar_product(p, e_inf())

    if abs(w) < epsilon() do
      raise ArgumentError, "cannot normalize point with zero weight, given #{inspect(p)}"
    end

    scale(1.0 / w, p)
  end

  @doc """
  Returns whether a multivector is a finite conformal point.

  A finite point is a grade-1 null vector with non-zero conformal weight.

  ## Examples

      iex> point?(point(1, 2, 3))
      true

      iex> point?(vector(1, 2, 3))
      false
  """
  def point?(p) do
    grade?(p, 1) and null?(p) and abs(scalar_product(p, e_inf())) > epsilon()
  end

  @doc """
  Removes coefficients whose absolute value is below `eps`.

  Use this after floating-point calculations to remove round-off noise. The
  default is the algebra's `epsilon/0` value.

  ## Examples

      iex> new(e1: 1.0, e2: 1.0e-12) |> cleanup() |> coefficient(:e2)
      0.0

      iex> new(e1: 1.0e-4) |> cleanup(1.0e-3) |> coefficient(:e1)
      0.0
  """
  def cleanup(m, eps \\ epsilon()) do
    %__MODULE__{data: data} = m

    data =
      data
      |> Tuple.to_list()
      |> Enum.map(fn coefficient -> if abs(coefficient) < eps, do: 0.0, else: coefficient end)
      |> List.to_tuple()

    %__MODULE__{data: data}
  end

  defp null?(p) do
    squared_norm = abs(scalar_product(p, p))

    scale =
      p.data
      |> Tuple.to_list()
      |> Enum.map(&abs/1)
      |> Enum.sum()

    squared_norm < epsilon() * max(scale * scale, 1.0)
  end

  # Handle IEEE-754 negative zero in coordinate results.
  defp clean_zero(x) when x == 0.0, do: 0.0
  defp clean_zero(x), do: x
end
