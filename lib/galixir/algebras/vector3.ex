defmodule Galixir.Algebras.Vector3 do
  @moduledoc """
  Three-dimensional Euclidean Geometric Algebra.

  This module implements:

      Cl(3,0)

  with signature:

      {1,1,1}

  and basis:

      e1, e2, e3

  Vectors are represented as grade-1 multivectors:

      v = x*e1 + y*e2 + z*e3

  The pseudoscalar:

      I = e123

  provides the duality operation between vectors and bivectors.

  Bivectors represent oriented planes and are the generators of
  rotations in 3D.

  ## Examples

      iex> v = Galixir.Algebras.Vector3.vector(1, 2, 3)
      iex> Galixir.Algebras.Vector3.coordinates(v)
      {1.0, 2.0, 3.0}

  """

  use Galixir.GeometricAlgebra,
    signature: {1, 1, 1},
    bases: {1, 2, 3}

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
  Returns the unit pseudoscalar.

  The pseudoscalar represents the oriented volume element:

      I = e1 ∧ e2 ∧ e3
  """
  def pseudoscalar do
    new(e123: 1)
  end

  # ----------------
  # Vectors
  # ----------------

  @doc """
  Creates a 3D vector.

  Creates:

      x*e1 + y*e2 + z*e3
  """
  def vector(x, y, z) do
    new(
      e1: x,
      e2: y,
      e3: z
    )
  end

  @doc """
  Extracts Cartesian coordinates from a vector.

  Returns:

      {x, y, z}
  """
  def coordinates(v) do
    {
      coefficient(v, :e1),
      coefficient(v, :e2),
      coefficient(v, :e3)
    }
  end

  # ----------------
  # Vector operations
  # ----------------

  @doc """
  Computes the dot product of two vectors.
  """
  def dot(a, b) do
    scalar_part(gp(a, b))
  end

  @doc """
  Computes the Euclidean length of a vector.
  """
  def len(v) do
    :math.sqrt(dot(v, v))
  end

  @doc """
  Normalizes a vector to unit length.
  """
  def normal(v) do
    scale(
      1 / len(v),
      v
    )
  end

  # ----------------
  # Exterior product
  # ----------------

  @doc """
  Computes the outer product of two vectors.

  The result is a bivector representing the oriented plane spanned
  by the two vectors.
  """
  def wedge(a, b) do
    grade(
      gp(a, b),
      2
    )
  end

  # ----------------
  # Cross product
  # ----------------

  @doc """
  Computes the 3D cross product.

  The cross product is obtained from the bivector outer product:

      a × b = -(a ∧ b)I

  where `I` is the pseudoscalar.
  """
  def cross(a, b) do
    coefficient(
      gp(
        wedge(a, b),
        pseudoscalar()
      ),
      :e123
    )
    |> negate()
  end

  # ----------------
  # Bivectors
  # ----------------
  #
  @doc """
  Creates a bivector from its coordinate plane components.

  A bivector in 3D represents an oriented plane element:

      B = xy*e12 + yz*e23 + zx*e31

  The components correspond to rotations in the coordinate planes:

      xy  - rotation plane in the XY plane
      yz  - rotation plane in the YZ plane
      zx  - rotation plane in the ZX plane
  """
  def bivector(xy, yz, zx) do
    new(
      e12: xy,
      e23: yz,
      e31: zx
    )
  end

  @doc """
  Returns the XY plane bivector.
  """
  def bivector_xy do
    bivector(1, 0, 0)
  end

  @doc """
  Returns the YZ plane bivector.
  """
  def bivector_yz do
    bivector(0, 1, 0)
  end

  @doc """
  Returns the ZX plane bivector.
  """
  def bivector_zx do
    bivector(0, 0, 1)
  end

  # ----------------
  # Rotors
  # ----------------

  @doc """
  Creates a rotor rotating around an axis.

  The axis vector is converted to its dual bivector plane.
  The resulting rotor is:

      R = cos(θ/2) - B sin(θ/2)

  where `B` is the normalized rotation plane bivector.

  The angle is specified in radians.
  """
  def rotor(axis, angle) do
    b =
      normalize(axis)
      |> dual()

    add(
      new(scalar: :math.cos(angle / 2)),
      scale(
        -:math.sin(angle / 2),
        b
      )
    )
  end

  @doc """
  Rotates a vector using a rotor.

  Applies the sandwich product:

      R v reverse(R)
  """
  def rotate(r, v) do
    gp(
      gp(r, v),
      reverse(r)
    )
  end

  # ----------------
  # Reflection
  # ----------------

  @doc """
  Reflects a vector in a plane with normal `n`.

  Uses:

      v' = -n v n⁻¹
  """
  def reflect(v, n) do
    scale(
      -1,
      gp(
        gp(n, v),
        inverse(n)
      )
    )
  end

  # ----------------
  # Helpers
  # ----------------

  @doc """
  Negates a multivector.
  """
  def negate(x) do
    scale(-1, x)
  end
end
