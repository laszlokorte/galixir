defmodule Galixir.Algebras.Complex1 do
  @moduledoc """
  Complex numbers represented as a one-dimensional geometric algebra.

  This module implements the complex numbers using the geometric algebra:

      Cl(0,1)

  with signature:

      {-1}

  The basis vector `e1` acts as the imaginary unit:

      e1² = -1

  A complex number:

      a + bi

  is represented as the multivector:

      a + b*e1

  ## Examples

      iex> z = Galixir.Algebras.Complex1.complex(3, 4)
      iex> Galixir.Algebras.Complex1.real(z)
      3.0


      iex> z = Galixir.Algebras.Complex1.complex(3, 4)
      iex> Galixir.Algebras.Complex1.imaginary(z)
      4.0
  """

  use Galixir.GeometricAlgebra,
    signature: {-1},
    bases: {1}

  @doc """
  Returns the zero complex number:

      0 + 0i
  """
  def zero do
    new()
  end

  @doc """
  Returns the multiplicative identity:

      1 + 0i
  """
  def one do
    new(scalar: 1)
  end

  @doc """
  Returns the imaginary unit.

  In this algebra:

      j² = -1
  """
  def j do
    new(e1: 1)
  end

  @doc """
  Constructs a complex number from real and imaginary parts.

  Creates:

      real + imag*j
  """
  def complex(real, imag) do
    new(
      scalar: real,
      e1: imag
    )
  end

  @doc """
  Extracts the real part of a complex number.
  """
  def real(z) do
    coefficient(z, :scalar)
  end

  @doc """
  Extracts the imaginary part of a complex number.
  """
  def imaginary(z) do
    coefficient(z, :e1)
  end

  @doc """
  Multiplies two complex numbers.

  This is equivalent to the geometric product:

      a * b = gp(a,b)
  """
  def multiply(a, b) do
    gp(a, b)
  end

  @doc """
  Computes the complex conjugate.

  For:

      z = a + bj

  returns:

      z̄ = a - bj
  """
  def conjugate(z) do
    new(
      scalar: real(z),
      e1: -imaginary(z)
    )
  end

  @doc """
  Computes the squared magnitude:

      |z|² = z * conjugate(z)

  Returns the scalar value.
  """
  def mag_squared(z) do
    squared_norm(z)
  end

  @doc """
  Computes the magnitude:

      |z| = sqrt(|z|²)
  """
  def mag(z) do
    norm(z)
  end

  @doc """
  Computes the multiplicative inverse.

  For a non-zero complex number:

      z⁻¹ = conjugate(z) / |z|²
  """
  def inv(z) do
    scale(
      1 / mag_squared(z),
      conjugate(z)
    )
  end

  @doc """
  Computes the complex argument.

  Returns the angle in radians:

      atan2(imaginary, real)
  """
  def arg(z) do
    :math.atan2(
      imaginary(z),
      real(z)
    )
  end

  @doc """
  Computes the complex exponential.

  For:

      z = a + bj

  computes:

      exp(z) = exp(a)(cos(b) + j sin(b))
  """
  def exp(z) do
    a = real(z)
    b = imaginary(z)

    complex(
      :math.exp(a) * :math.cos(b),
      :math.exp(a) * :math.sin(b)
    )
  end

  @doc """
  Computes the principal complex logarithm.

  Returns:

      log(z) = log(|z|) + arg(z)j
  """
  def log(z) do
    complex(
      :math.log(mag(z)),
      arg(z)
    )
  end

  @doc """
  Computes complex exponentiation.

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
  Computes the scalar product of two multivectors.
  """
  def dot(a, b) do
    scalar_part(gp(a, b))
  end
end
