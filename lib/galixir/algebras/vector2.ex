defmodule Galixir.Algebras.Vector2 do
  @moduledoc """
  Two-dimensional Euclidean Geometric Algebra.

  This module implements the geometric algebra:

      Cl(2,0)

  with signature:

      {1,1}

  and basis:

      e1, e2

  Vectors are represented as grade-1 multivectors:

      v = x*e1 + y*e2

  The bivector:

      e12 = e1 ∧ e2

  represents the oriented plane element and is the generator of rotations
  in two dimensions.

  ## Examples

      iex> v = Galixir.Algebras.Vector2.vector(3, 4)
      iex> Galixir.Algebras.Vector2.len(v)
      5.0

  """

  use Galixir.GeometricAlgebra,
    signature: {1, 1},
    bases: {1, 2}

  @doc """
  Returns the zero vector.
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

  The pseudoscalar represents the oriented plane:

      I = e1 ∧ e2
  """
  def pseudoscalar do
    new(e12: 1)
  end

  # ----------------
  # Vectors
  # ----------------

  @doc """
  Creates a 2D vector.

  Creates:

      x*e1 + y*e2
  """
  def vector(x, y) do
    new(
      e1: x,
      e2: y
    )
  end

  @doc """
  Extracts Cartesian coordinates from a vector.

  Returns:

      {x, y}
  """
  def coordinates(v) do
    {
      coefficient(v, :e1),
      coefficient(v, :e2)
    }
  end

  # ----------------
  # Vector operations
  # ----------------

  @doc """
  Computes the dot product of two vectors.

  Returns the scalar part of the geometric product.
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
  # Geometric products
  # ----------------

  @doc """
  Computes the outer product of two vectors.

  Returns the grade-2 part:

      a ∧ b

  which is a scalar multiple of the pseudoscalar.
  """
  def wedge(a, b) do
    grade(
      gp(a, b),
      2
    )
  end

  @doc """
  Computes the signed 2D cross product.

  In two dimensions the cross product is a scalar representing the
  oriented area:

      a × b = (a ∧ b) / e12

  The sign indicates orientation.
  """
  def cross(a, b) do
    coefficient(
      gp(a, b),
      :e12
    )
  end

  # ----------------
  # Rotations
  # ----------------

  @doc """
  Creates a rotation rotor.

  The rotor represents a rotation by `angle` radians:

      R = cos(angle/2) + e12*sin(angle/2)

  """
  def rotor(angle) do
    new(
      scalar: :math.cos(angle / 2),
      e12: :math.sin(angle / 2)
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
  Reflects a vector about a line with normal `n`.

  Uses the reflection formula:

      v' = -n v n⁻¹
  """
  def reflect(v, n) do
    negate(
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

  @doc """
  Computes the signed angle from vector `a` to vector `b`.

  Returns the angle in radians.
  """
  def angle(a, b) do
    :math.atan2(
      cross(a, b),
      dot(a, b)
    )
  end
end
