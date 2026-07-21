defmodule Galixir.Algebras.CGA3 do
  use Galixir.GeometricAlgebra,
    signature: {1, 1, 1, 1, -1},
    bases: {1, 2, 3, :p, :m}

  #
  # Constants
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

  def e0 do
    scale(
      0.5,
      add(
        new(pm: 1),
        new(pp: 1)
      )
    )
  end

  def einf do
    sub(
      new(m: 1),
      new(p: 1)
    )
  end

  #
  # Euclidean vectors
  #

  def vector(x, y, z) do
    new(
      e1: x,
      e2: y,
      e3: z
    )
  end

  #
  # Points
  #

  def point(x, y, z) do
    add(
      add(
        e0(),
        vector(x, y, z)
      ),
      scale(
        0.5 * (x * x + y * y + z * z),
        einf()
      )
    )
  end

  def origin do
    point(0, 0, 0)
  end

  def point_coordinates(p) do
    w = -dot(p, einf())

    {
      dot(p, new(e1: 1)) / w,
      dot(p, new(e2: 1)) / w,
      dot(p, new(e3: 1)) / w
    }
  end

  #
  # Basic CGA objects
  #

  # line through two points
  def line(a, b) do
    wedge(
      wedge(a, b),
      einf()
    )
  end

  # plane through three points
  def plane(a, b, c) do
    wedge(
      wedge(a, b),
      c
    )
    |> wedge(einf())
  end

  # sphere through four points
  def sphere(a, b, c, d) do
    wedge(
      wedge(
        wedge(a, b),
        c
      ),
      d
    )
  end

  def sphere(center, radius) do
    sub(
      center,
      scale(
        0.5 * radius * radius,
        einf()
      )
    )
  end

  #
  # Intersections
  #

  def meet(a, b) do
    dual(
      wedge(
        dual(a),
        dual(b)
      )
    )
  end

  def join(a, b) do
    wedge(a, b)
  end

  def contains?(object, point) do
    zero?(meet(object, point))
  end

  #
  # Motors
  #

  def translator(x, y, z) do
    t =
      add(
        one(),
        scale(
          -0.5,
          gp(
            vector(x, y, z),
            einf()
          )
        )
      )

    normalize(t)
  end

  def translator(v) do
    translator(
      coefficient(v, :e1),
      coefficient(v, :e2),
      coefficient(v, :e3)
    )
  end

  def rotor(bivector, angle) do
    bivector = normalize(bivector)

    add(
      new(scalar: :math.cos(angle / 2)),
      scale(
        -:math.sin(angle / 2),
        bivector
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
    gp(
      blade_inverse(pseudoscalar()),
      x
    )
  end

  def pseudoscalar do
    new(e123pm: 1)
  end
end
