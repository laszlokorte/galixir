defmodule Galixir.Algebras.Vector2 do
  use Galixir.GeometricAlgebra,
    signature: {1, 1},
    bases: {1, 2}

  #
  # Constants
  #

  def zero do
    new()
  end

  def one do
    new(scalar: 1)
  end

  def pseudoscalar do
    new(e12: 1)
  end

  #
  # Vectors
  #

  def vector(x, y) do
    new(
      e1: x,
      e2: y
    )
  end

  def coordinates(v) do
    {
      coefficient(v, :e1),
      coefficient(v, :e2)
    }
  end

  #
  # Vector operations
  #

  def dot(a, b) do
    scalar_part(gp(a, b))
  end

  def len(v) do
    :math.sqrt(dot(v, v))
  end

  def normal(v) do
    scale(
      1 / len(v),
      v
    )
  end

  #
  # Geometric products
  #

  def wedge(a, b) do
    grade(
      gp(a, b),
      2
    )
  end

  def cross(a, b) do
    coefficient(
      gp(a, b),
      :e12
    )
  end

  #
  # Rotations
  #

  def rotor(angle) do
    new(
      scalar: :math.cos(angle / 2),
      e12: :math.sin(angle / 2)
    )
  end

  def rotate(r, v) do
    gp(
      gp(r, v),
      reverse(r)
    )
  end

  #
  # Reflection
  #

  def reflect(v, n) do
    negate(
      gp(
        gp(n, v),
        inverse(n)
      )
    )
  end

  #
  # Helpers
  #

  def negate(x) do
    scale(-1, x)
  end

  def angle(a, b) do
    :math.atan2(
      cross(a, b),
      dot(a, b)
    )
  end
end
