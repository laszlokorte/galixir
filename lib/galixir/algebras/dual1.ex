defmodule Galixir.Algebras.Dual1 do
  @moduledoc """
  Dual numbers represented as a one-dimensional degenerate geometric algebra.

  This module implements the dual number algebra:

      D = R[ε] / (ε²)

  using the signature:

      {0}

  The basis element `e1` represents the infinitesimal unit:

      ε² = 0

  A dual number:

      a + bε

  consists of:

    * `a` - the real component
    * `b` - the infinitesimal component

  Dual numbers are useful for automatic differentiation because the
  infinitesimal coefficient propagates derivatives through arithmetic
  operations and elementary functions.
  """

  use Galixir.GeometricAlgebra,
    signature: {0},
    bases: {1}

  @doc """
  Returns the zero dual number:

      0 + 0ε
  """
  def zero do
    new()
  end

  @doc """
  Returns the multiplicative identity:

      1 + 0ε
  """
  def one do
    new(scalar: 1)
  end

  @doc """
  Returns the infinitesimal unit.

  The infinitesimal satisfies:

      ε² = 0
  """
  def epsilon do
    new(e1: 1)
  end

  @doc """
  Constructs a dual number.

  Creates:

      real + infinitesimal*ε
  """
  def dual(real, infinitesimal) do
    new(
      scalar: real,
      e1: infinitesimal
    )
  end

  @doc """
  Extracts the real component.
  """
  def real(x) do
    coefficient(x, :scalar)
  end

  @doc """
  Extracts the infinitesimal component.

  This corresponds to the derivative component when using dual numbers
  for automatic differentiation.
  """
  def infinitesimal(x) do
    coefficient(x, :e1)
  end

  @doc """
  Computes the dual conjugate.

  For:

      x = a + bε

  returns:

      x* = a - bε
  """
  def conjugate(x) do
    new(
      scalar: real(x),
      e1: -infinitesimal(x)
    )
  end

  @doc """
  Extracts the derivative component.

  Equivalent to returning the infinitesimal coefficient.
  """
  def derivative(x) do
    infinitesimal(x)
  end

  @doc """
  Computes the multiplicative inverse.

  For:

      x = a + bε

  where `a != 0`:

      x⁻¹ = 1/a - b/a² ε
  """
  def inv(x) do
    a = real(x)
    b = infinitesimal(x)

    if a == 0 do
      raise "dual number with zero real part has no inverse"
    end

    dual(
      1 / a,
      -b / (a * a)
    )
  end

  @doc """
  Computes the exponential function.

  For:

      x = a + bε

  returns:

      exp(x) = exp(a) + b exp(a) ε
  """
  def exp(x) do
    a = real(x)
    b = infinitesimal(x)

    dual(
      :math.exp(a),
      b * :math.exp(a)
    )
  end

  @doc """
  Computes the natural logarithm.

  For:

      x = a + bε

  returns:

      log(x) = log(a) + b/a ε
  """
  def log(x) do
    a = real(x)
    b = infinitesimal(x)

    dual(
      :math.log(a),
      b / a
    )
  end

  @doc """
  Computes the sine function.

  The infinitesimal component contains the derivative:

      d/dx sin(x) = cos(x)
  """
  def sin(x) do
    a = real(x)
    b = infinitesimal(x)

    dual(
      :math.sin(a),
      b * :math.cos(a)
    )
  end

  @doc """
  Computes the cosine function.

  The infinitesimal component contains the derivative:

      d/dx cos(x) = -sin(x)
  """
  def cos(x) do
    a = real(x)
    b = infinitesimal(x)

    dual(
      :math.cos(a),
      -b * :math.sin(a)
    )
  end

  @doc """
  Computes the square root.

  For:

      x = a + bε

  returns:

      sqrt(x) = sqrt(a) + b/(2sqrt(a)) ε
  """
  def sqrt(x) do
    a = real(x)
    b = infinitesimal(x)

    s = :math.sqrt(a)

    dual(
      s,
      b / (2 * s)
    )
  end

  @doc """
  Returns the normalized (real) value of a dual number.

  This discards the infinitesimal component.
  """
  def normal(x) do
    real(x)
  end

  @doc """
  Computes the scalar product of two dual multivectors.
  """
  def dot(a, b) do
    scalar_part(gp(a, b))
  end
end
