defmodule Galixir.Algebras.CGA2 do
  use Galixir.GeometricAlgebra,
    signature: {1, 1, 1, -1},
    bases: {1, 2, :p, :m}

  #
  # Basic elements
  #
  def zero do
    new()
  end

  def one do
    new(scalar: 1)
  end

  #
  # Conformal basis
  #

  def e_inf do
    new(em: 1, ep: -1)
  end

  def e_o do
    scale(
      0.5,
      add(
        new(em: 1),
        new(ep: 1)
      )
    )
  end

  #
  # Euclidean vectors
  #

  def vector(x, y) do
    new(
      e1: x,
      e2: y
    )
  end

  #
  # Embed point
  #

  def point(x, y) do
    add(
      add(
        e_o(),
        vector(x, y)
      ),
      scale(
        0.5 * (x * x + y * y),
        e_inf()
      )
    )
  end

  #
  # Extract coordinates
  #

  def point_coordinates(p) do
    w = -dot(p, e_inf())

    {
      dot(p, new(e1: 1)) / w,
      dot(p, new(e2: 1)) / w
    }
  end

  #
  # Sphere / circle primitives
  #

  def circle(center, radius) do
    {x, y} = point_coordinates(center)

    sub(
      point(x, y),
      scale(
        0.5 * radius * radius,
        e_inf()
      )
    )
  end

  def circle(x, y, r) do
    circle(point(x, y), r)
  end

  #
  # Lines
  #

  def line(a, b) do
    wedge(
      wedge(
        a,
        b
      ),
      e_inf()
    )
  end

  def plane_from_points(a, b, c) do
    wedge(
      wedge(
        wedge(a, b),
        c
      ),
      e_inf()
    )
  end

  #
  # Incidence
  #

  def contains?(object, point) do
    zero?(meet(object, point))
  end

  def meet(a, b) do
    wedge(a, b)
  end

  #
  # Transformations
  #

  def translator(x, y) do
    t =
      add(
        one(),
        scale(
          -0.5,
          gp(
            vector(x, y),
            e_inf()
          )
        )
      )

    normalize(t)
  end

  def rotor(angle) do
    add(
      new(scalar: :math.cos(angle / 2)),
      scale(
        -:math.sin(angle / 2),
        new(e12: 1)
      )
    )
  end

  def transform(motor, object) do
    gp(
      gp(motor, object),
      reverse(motor)
    )
  end

  #
  # Helpers
  #

  def dot(a, b) do
    scalar_part(gp(a, b))
  end

  def dual(x) do
    blade_inverse(pseudoscalar())
    |> gp(x)
  end

  def pseudoscalar do
    new(e12pm: 1)
  end
end
