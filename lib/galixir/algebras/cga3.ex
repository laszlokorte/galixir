defmodule Galixir.Algebras.CGA3 do
  @moduledoc """
  Three-dimensional Conformal Geometric Algebra (CGA).

  This module implements CGA for Euclidean 3-space using the signature:

      {1, 1, 1, 1, -1}

  with basis:

      e1, e2, e3, ep, em

  The Euclidean basis vectors represent ordinary 3D coordinates.
  The additional conformal basis vectors are combined into the null vectors:

      e0   = (ep + em) / 2
      einf = em - ep

  Points are embedded into conformal space using:

      P(x,y,z) =
        e0
        + x*e1
        + y*e2
        + z*e3
        + 1/2(x²+y²+z²)einf

  Geometric objects such as lines, planes, and spheres are represented as
  multivectors using outer products.

  ## Examples

      iex> p = Galixir.Algebras.CGA3.point(1, 2, 3)
      iex> Galixir.Algebras.CGA3.point_coordinates(p)
      {1.0, 2.0, 3.0}
  """

  use Galixir.GeometricAlgebra,
    signature: {1, 1, 1, 1, -1},
    bases: {1, 2, 3, :p, :m}

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
  Returns the conformal origin vector.

  Defined as:

      e0 = (ep + em) / 2
  """
  def e0 do
    scale(
      0.5,
      add(
        new(em: 1),
        new(ep: 1)
      )
    )
  end

  @doc """
  Returns the infinity vector.

  The infinity vector represents the point at infinity:

      einf = em - ep
  """
  def einf do
    sub(
      new(em: 1),
      new(ep: 1)
    )
  end

  @doc """
  Creates a Euclidean vector.

  This creates only the Euclidean part:

      x*e1 + y*e2 + z*e3

  Use `point/3` to create a conformal point.
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

      P = e0 + x*e1 + y*e2 + z*e3
          + 1/2(x²+y²+z²)einf
  """
  def point(x, y, z) do
    add(
      add(
        e0(),
        vector(x, y, z)
      ),
      scale(
        0.5 * (x * x + y * y + z * z),
        einf()
      )
    )
  end

  @doc """
  Returns the conformal representation of the Euclidean origin.
  """
  def origin do
    point(0, 0, 0)
  end

  @doc """
  Extracts Euclidean coordinates from a conformal point.

  Returns:

      {x, y, z}
  """
  def point_coordinates(p) do
    w = -dot(p, einf())

    {
      dot(p, new(e1: 1)) / w,
      dot(p, new(e2: 1)) / w,
      dot(p, new(e3: 1)) / w
    }
  end

  @doc """
  Creates a line through two conformal points.

  The line is represented by:

      L = a ∧ b ∧ einf
  """
  def line(a, b) do
    wedge(
      wedge(a, b),
      einf()
    )
  end

  @doc """
  Creates a plane through three conformal points.

  The plane is represented by:

      Π = a ∧ b ∧ c ∧ einf
  """
  def plane(a, b, c) do
    wedge(
      wedge(
        wedge(a, b),
        c
      ),
      einf()
    )
  end

  @doc """
  Creates a sphere through four conformal points.

  The resulting multivector represents the unique sphere containing
  the four points.
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

  The radius is encoded using the infinity vector term.
  """
  def sphere(center, radius) do
    sub(
      center,
      scale(
        0.5 * radius * radius,
        einf()
      )
    )
  end

  @doc """
  Computes the meet (intersection) of two CGA objects.

  The meet is implemented through duality:

      meet(a,b) = dual(dual(a) ∧ dual(b))
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
  """
  def join(a, b) do
    wedge(a, b)
  end

  @doc """
  Tests whether a conformal point lies on an object.
  """
  def contains?(object, point) do
    zero?(meet(object, point))
  end

  @doc """
  Creates a translator motor.

  The motor translates objects by the Euclidean displacement:

      {x,y,z}
  """
  def translator(x, y, z) do
    t =
      add(
        one(),
        scale(
          -0.5,
          gp(
            vector(x, y, z),
            einf()
          )
        )
      )

    normalize(t)
  end

  @doc """
  Creates a translator motor from a Euclidean vector.
  """
  def translator(v) do
    translator(
      coefficient(v, :e1),
      coefficient(v, :e2),
      coefficient(v, :e3)
    )
  end

  @doc """
  Creates a rotor from a normalized bivector and angle.

  The angle is measured in radians.
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

  Uses the sandwich product:

      M X reverse(M)
  """
  def transform(motor, object) do
    gp(
      gp(motor, object),
      reverse(motor)
    )
  end

  @doc """
  Computes the scalar product of two multivectors.

  Returns the scalar part of their geometric product.
  """
  def dot(a, b) do
    scalar_part(gp(a, b))
  end

  @doc """
  Computes the conformal dual of a multivector.

  The dual is calculated using the inverse pseudoscalar.
  """
  def dual(x) do
    gp(
      blade_inverse(pseudoscalar()),
      x
    )
  end

  @doc """
  Returns the CGA3 pseudoscalar:

      e1 ∧ e2 ∧ e3 ∧ ep ∧ em
  """
  def pseudoscalar do
    new(e123pm: 1)
  end
end
