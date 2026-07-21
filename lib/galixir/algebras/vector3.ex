defmodule Galixir.Algebras.Vector3 do
  use Galixir.GeometricAlgebra,
    signature: {1, 1, 1},
    bases: {1, 2, 3}

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
    new(e123: 1)
  end

  #
  # Vectors
  #

  def vector(x, y, z) do
    new(
      e1: x,
      e2: y,
      e3: z
    )
  end

  def coordinates(v) do
    {
      coefficient(v, :e1),
      coefficient(v, :e2),
      coefficient(v, :e3)
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
  # Exterior product
  #

  def wedge(a, b) do
    grade(
      gp(a, b),
      2
    )
  end

  #
  # Cross product
  #
  # a × b = -(a ∧ b) I
  #

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

  #
  # Bivectors
  #

  def bivector_xy do
    new(e12: 1)
  end

  def bivector_yz do
    new(e23: 1)
  end

  def bivector_zx do
    new(e31: 1)
  end

  #
  # Rotors
  #

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
    scale(
      -1,
      gp(
        gp(n, v),
        inverse(n)
      )
    )
  end

  #
  # Duality
  #

  #
  # Helpers
  #

  def negate(x) do
    scale(-1, x)
  end
end
