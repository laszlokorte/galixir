defmodule Galixir.Algebras.Dual1 do
  use Galixir.GeometricAlgebra,
    signature: {0},
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

  def epsilon do
    new(e1: 1)
  end

  #
  # Construction
  #

  def dual(real, infinitesimal) do
    new(
      scalar: real,
      e1: infinitesimal
    )
  end

  def real(x) do
    coefficient(x, :scalar)
  end

  def infinitesimal(x) do
    coefficient(x, :e1)
  end

  #
  # Dual operations
  #

  def conjugate(x) do
    new(
      scalar: real(x),
      e1: -infinitesimal(x)
    )
  end

  def derivative(x) do
    infinitesimal(x)
  end

  #
  # Inverse
  #

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

  #
  # Functions
  #

  def exp(x) do
    a = real(x)
    b = infinitesimal(x)

    dual(
      :math.exp(a),
      b * :math.exp(a)
    )
  end

  def log(x) do
    a = real(x)
    b = infinitesimal(x)

    dual(
      :math.log(a),
      b / a
    )
  end

  def sin(x) do
    a = real(x)
    b = infinitesimal(x)

    dual(
      :math.sin(a),
      b * :math.cos(a)
    )
  end

  def cos(x) do
    a = real(x)
    b = infinitesimal(x)

    dual(
      :math.cos(a),
      -b * :math.sin(a)
    )
  end

  def sqrt(x) do
    a = real(x)
    b = infinitesimal(x)

    s = :math.sqrt(a)

    dual(
      s,
      b / (2 * s)
    )
  end

  #
  # Helpers
  #

  def normal(x) do
    real(x)
  end

  def dot(a, b) do
    scalar_part(gp(a, b))
  end
end
