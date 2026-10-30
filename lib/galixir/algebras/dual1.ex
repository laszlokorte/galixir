defmodule Galixir.Algebras.Dual1 do
  @moduledoc """
  Dual numbers represented as a one-dimensional degenerate geometric algebra.

  This module implements the dual number algebra:

      D = R[ε] / (ε²)

  using the metric:

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
  operations and elementary functions when the input is seeded with an
  infinitesimal coefficient of `1`.
  """

  use Galixir.GeometricAlgebra,
    metric: {0},
    bases: {"1"},
    exp: false

  @doc """
  Returns the infinitesimal unit.

  The infinitesimal satisfies: `ε² = 0`
  """
  def eps do
    new(e1: 1)
  end

  @doc """
  Constructs a dual number.

  Creates: `real + infinitesimal * ε`
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

  For an input seeded as `dual(x, 1)`, this is the derivative component
  after applying a differentiable function.
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

  Equivalent to returning the infinitesimal coefficient. For automatic
  differentiation, seed the input with `dual(x, 1)`.
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
      raise ArgumentError, "dual number with zero real part has no inverse"
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
  def exp(%__MODULE__{} = x) do
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

  for `a > 0`, returns:

      log(x) = log(a) + b/a ε
  """
  def log(%__MODULE__{} = x) do
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

  For: `x = a + bε`

  for `a > 0`, returns:

      sqrt(x) = sqrt(a) + b/(2sqrt(a)) ε
  """
  def sqrt(x) do
    a = real(x)
    b = infinitesimal(x)

    s = a ** 0.5

    dual(
      s,
      b / (2 * s)
    )
  end

  @doc """
  Returns the real coefficient of a dual number.

  This discards the infinitesimal component; it does not normalize the
  dual number to unit length.
  """
  def normal(x) do
    real(x)
  end

  @doc """
  Returns the scalar part of the geometric product.

  For `a + bε` and `c + dε`, this is `a*c`; the infinitesimal
  coefficients do not contribute.
  """
  def scalar_product(a, b) do
    scalar_part(gp(a, b))
  end
end
