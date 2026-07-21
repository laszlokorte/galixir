defmodule Galixir.Algebras.Hyper1 do
  @moduledoc """
  Hyperbolic numbers represented as a one-dimensional geometric algebra.

  This module implements the split-complex (hyperbolic) numbers using the
  geometric algebra:

      Cl(1,0)

  with signature:

      {1}

  The basis element `e1` acts as the hyperbolic unit:

      j² = +1

  A hyperbolic number:

      a + bj

  is represented as the multivector:

      a + b*e1

  Unlike complex numbers, hyperbolic numbers contain zero divisors:

      (1 + j)(1 - j) = 0

  because:

      j² = 1

  ## Examples

      iex> z = Galixir.Algebras.Hyper1.hyper(3, 2)
      iex> Galixir.Algebras.Hyper1.real(z)
      3.0

      iex> z = Galixir.Algebras.Hyper1.hyper(3, 2)
      iex> Galixir.Algebras.Hyper1.hyper_part(z)
      2.0
  """

  use Galixir.GeometricAlgebra,
    signature: {1},
    bases: {1}

  @doc """
  Returns the zero hyperbolic number:

      0 + 0j
  """
  def zero do
    new()
  end

  @doc """
  Returns the multiplicative identity:

      1 + 0j
  """
  def one do
    new(scalar: 1)
  end

  @doc """
  Returns the hyperbolic unit.

  The unit satisfies:

      j² = 1
  """
  def j do
    new(e1: 1)
  end

  @doc """
  Constructs a hyperbolic number.

  Creates:

      real + hyper* j
  """
  def hyper(real, hyper) do
    new(
      scalar: real,
      e1: hyper
    )
  end

  @doc """
  Extracts the real component.
  """
  def real(z) do
    coefficient(z, :scalar)
  end

  @doc """
  Extracts the hyperbolic component.

  This is the coefficient of the hyperbolic unit `j`.
  """
  def hyper_part(z) do
    coefficient(z, :e1)
  end

  @doc """
  Computes the hyperbolic conjugate.

  For:

      z = a + bj

  returns:

      z̄ = a - bj
  """
  def conjugate(z) do
    new(
      scalar: real(z),
      e1: -hyper_part(z)
    )
  end

  @doc """
  Computes the squared norm.

  For:

      z = a + bj

  returns:

      |z|² = a² - b²

  The norm is not positive definite because hyperbolic numbers have an
  indefinite metric.
  """
  def norm_squared(z) do
    coefficient(
      gp(z, conjugate(z)),
      :scalar
    )
  end

  @doc """
  Computes the multiplicative inverse.

  The inverse exists only when:

      a² - b² != 0

  Hyperbolic numbers on the null cone are zero divisors and cannot be
  inverted.
  """
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

  @doc """
  Computes the hyperbolic exponential.

  For:

      z = a + bj

  returns:

      exp(z) =
        exp(a)(cosh(b) + j*sinh(b))
  """
  def exp(z) do
    a = real(z)
    b = hyper_part(z)

    hyper(
      :math.exp(a) * :math.cosh(b),
      :math.exp(a) * :math.sinh(b)
    )
  end

  @doc """
  Computes the principal hyperbolic logarithm.

  Returns:

      log(z) =
        log(|z|) + atanh(b/a)j
  """
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

  @doc """
  Computes hyperbolic exponentiation.

  Calculates:

      z^t = exp(t * log(z))
  """
  def pow(z, t) do
    exp(
      scale(
        t,
        log(z)
      )
    )
  end

  @doc """
  Computes the scalar product of two hyperbolic multivectors.
  """
  def dot(a, b) do
    scalar_part(gp(a, b))
  end
end
