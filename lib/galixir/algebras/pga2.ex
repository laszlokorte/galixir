defmodule Galixir.Algebras.PGA2 do
  use Galixir.GeometricAlgebra, signature: {1, 1, 0}, bases: {1, 2, 0}

  def zero do
    new()
  end

  def one do
    new(scalar: 1)
  end

  def origin do
    point(0, 0)
  end

  # ----------------
  # Points
  # ----------------

  def point(x, y) do
    new(
      e12: 1,
      e20: x,
      e01: y
    )
  end

  def ideal_point(x, y) do
    new(
      e20: x,
      e01: y
    )
  end

  def finite_point?(p) do
    homogeneous_grade(p) == 2 and
      coefficient(p, :e12) != 0
  end

  def ideal_point?(p) do
    homogeneous_grade(p) == 2 and
      coefficient(p, :e12) == 0
  end

  def point_coordinates(p) do
    w = coefficient(p, :e12)

    {
      coefficient(p, :e20) / w,
      coefficient(p, :e01) / w
    }
  end

  # ----------------
  # Vectors
  # ----------------

  def vector(x, y) do
    new(
      e1: x,
      e2: y
    )
  end

  # ----------------
  # Lines
  # ----------------

  def line(a, b, c) do
    new(
      e1: a,
      e2: b,
      e0: c
    )
  end

  def line(a, b) do
    join(a, b)
  end

  def line_normal(l) do
    vector(
      coefficient(l, :e1),
      coefficient(l, :e2)
    )
  end

  def unit_line_normal(l) do
    normalize(line_normal(l))
  end

  def line_from_normal_point(n, p) do
    n = normalize(n)
    {x, y} = point_coordinates(p)

    a = coefficient(n, :e1)
    b = coefficient(n, :e2)

    line(
      a,
      b,
      -(a * x + b * y)
    )
  end

  # ----------------
  # Join / meet
  # ----------------

  def join(a, b) do
    undual(wedge(dual(a), dual(b)))
  end

  def meet(a, b) do
    wedge(a, b)
  end

  def incident?(a, b) do
    zero?(join(a, b))
  end

  def contains?(container, object) do
    zero?(join(container, object))
  end

  # ----------------
  # Directions
  # ----------------

  def ideal_direction(line) do
    meet(line, new(e0: 1))
  end

  def direction_vector(line) do
    d = ideal_direction(line)

    vector(
      coefficient(d, :e20),
      coefficient(d, :e01)
    )
  end

  def unit_direction_vector(line) do
    normalize(direction_vector(line))
  end

  # ----------------
  # Transformations
  # ----------------

  def translator(x, y) do
    new(
      scalar: 1,
      e01: x / 2,
      e02: y / 2
    )
  end

  def translator(v) do
    translator(
      coefficient(v, :e1),
      coefficient(v, :e2)
    )
  end

  def rotor(angle) do
    new(
      scalar: :math.cos(angle / 2),
      e12: -:math.sin(angle / 2)
    )
    |> normalize()
  end

  def transform(motor, object) do
    gp(gp(motor, object), inverse(motor))
  end

  # ----------------
  # Utility
  # ----------------

  def negate(x) do
    scale(-1, x)
  end

  def distance(a, b) do
    {ax, ay} = point_coordinates(a)
    {bx, by} = point_coordinates(b)

    dx = ax - bx
    dy = ay - by

    :math.sqrt(dx * dx + dy * dy)
  end

  def homogeneous_grade(x) do
    case grades(x) do
      [g] -> g
      _ -> nil
    end
  end

  def dot(a, b) do
    gp(a, b)
    |> scalar_part()
  end
end
