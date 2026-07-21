defmodule Galixir.Algebras.Complex1 do
  use Galixir.GeometricAlgebra,
    signature: {-1},
    bases: {1}

  #
  # Constants
  #

  def zero do
    new()
  end

  def one do
    new(scalar: 1)
  end

  def j do
    new(e1: 1)
  end

  #
  # Construction
  #

  def complex(real, imag) do
    new(
      scalar: real,
      e1: imag
    )
  end

  def real(z) do
    coefficient(z, :scalar)
  end

  def imaginary(z) do
    coefficient(z, :e1)
  end

  #
  # Arithmetic
  #

  def multiply(a, b) do
    gp(a, b)
  end

  #
  # Complex operations
  #

  def conjugate(z) do
    new(
      scalar: real(z),
      e1: -imaginary(z)
    )
  end

  def norm_squared(z) do
    scalar_part(
      gp(
        z,
        conjugate(z)
      )
    )
  end

  def mag(z) do
    :math.sqrt(norm_squared(z))
  end

  def inv(z) do
    scale(
      1 / norm_squared(z),
      conjugate(z)
    )
  end

  def arg(z) do
    :math.atan2(
      imaginary(z),
      real(z)
    )
  end

  def exp(z) do
    a = real(z)
    b = imaginary(z)

    complex(
      :math.exp(a) * :math.cos(b),
      :math.exp(a) * :math.sin(b)
    )
  end

  def log(z) do
    complex(
      :math.log(mag(z)),
      arg(z)
    )
  end

  def pow(z, t) do
    exp(
      scale(
        t,
        log(z)
      )
    )
  end

  #
  # Helpers
  #

  def dot(a, b) do
    scalar_part(gp(a, b))
  end
end
