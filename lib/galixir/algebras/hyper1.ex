defmodule Galixir.Algebras.Hyper1 do
  use Galixir.GeometricAlgebra,
    signature: {1},
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

  def hyper(real, hyper) do
    new(
      scalar: real,
      e1: hyper
    )
  end

  def real(z) do
    coefficient(z, :scalar)
  end

  def hyper_part(z) do
    coefficient(z, :e1)
  end

  #
  # Conjugation
  #

  def conjugate(z) do
    new(
      scalar: real(z),
      e1: -hyper_part(z)
    )
  end

  #
  # Norm
  #

  def norm_squared(z) do
    coefficient(
      gp(z, conjugate(z)),
      :scalar
    )
  end

  #
  # Inverse
  #

  def inv(z) do
    n = norm_squared(z)

    if n == 0 do
      raise "hyperbolic number has no inverse (zero divisor)"
    end

    scale(
      1 / n,
      conjugate(z)
    )
  end

  #
  # Functions
  #

  def exp(z) do
    a = real(z)
    b = hyper_part(z)

    hyper(
      :math.exp(a) * :math.cosh(b),
      :math.exp(a) * :math.sinh(b)
    )
  end

  def log(z) do
    a = real(z)
    b = hyper_part(z)

    r =
      :math.sqrt(abs(a * a - b * b))

    hyper(
      :math.log(r),
      :math.atanh(b / a)
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
