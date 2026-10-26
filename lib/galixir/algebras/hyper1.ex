defmodule Galixir.Algebras.Hyper1 do
  @moduledoc """
  Hyperbolic numbers represented as a one-dimensional geometric algebra.

  This module implements the split-complex (hyperbolic) numbers using the
  geometric algebra:

      Cl(1, 0)

  with metric:

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
    metric: {1},
    bases: {"1"}

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

      N(z) = z * conjugate(z) = a² - b²

  This signed quantity can be negative or zero for non-zero numbers;
  it is not a non-negative magnitude squared.
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
      raise ArgumentError, "hyperbolic number has no inverse (zero divisor)"
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
  Computes a real split-complex logarithm in the positive timelike cone.

  For `z = a + bj` with `a > |b|`, returns:

      log(z) = log(sqrt(a² - b²)) + atanh(b/a)j

  Outside this domain the implementation may raise or return a value whose
  exponential is not `z`; it does not handle the other timelike cone.
  """
  def log(z) do
    a = real(z)
    b = hyper_part(z)

    r =
      abs(a * a - b * b) ** 0.5

    hyper(
      :math.log(r),
      :math.atanh(b / a)
    )
  end

  @doc """
  Raises a hyperbolic number in the positive timelike cone to a real
  scalar exponent `t` via `log/1`.

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
  Returns the scalar part of the geometric product.

  For `a + bj` and `c + dj`, this is `a*c + b*d`, not the
  conjugate-based bilinear form `a*c - b*d`.
  """
  def scalar_product(a, b) do
    scalar_part(gp(a, b))
  end
end
