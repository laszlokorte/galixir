defmodule Galixir.Algebras.PGA3 do
  use Galixir.GeometricAlgebra,
    signature: {1, 1, 1, 0}

  def point(x, y, z) do
    new(
      e123: 1,
      e234: x,
      e134: -y,
      e124: z
    )
  end

  def vector(x, y, z) do
    new(
      e1: x,
      e2: y,
      e3: z
    )
  end

  def line(a, b) do
    join(a, b)
  end

  def plane(a, b, c, d) do
    new(
      e1: a,
      e2: b,
      e3: c,
      e4: -d
    )
  end

  def translation(v) do
    new(
      scalar: 1,
      e14: -coefficient(v, :e1) / 2,
      e24: -coefficient(v, :e2) / 2,
      e34: -coefficient(v, :e3) / 2
    )
  end

  def rotation_between_vectors(a, b) do
    a = normalize(a)
    b = normalize(b)

    s = 1 + scalar_part(gp(a, b))

    if s < 1.0e-8 do
      raise "opposite vectors need special handling"
    end

    r =
      add(
        new(scalar: 1),
        gp(b, a)
      )

    scale(1 / :math.sqrt(s * 2), r)
  end

  def direction_between_points(p, q) do
    d = sub(q, p)

    vector(
      coefficient(d, :e234),
      -coefficient(d, :e134),
      coefficient(d, :e124)
    )
  end

  def join(a, b) do
    dual(wedge(dual(a), dual(b)))
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

  def parallel?(a, b) do
    ideal?(meet(a, b))
  end

  def intersects?(a, b) do
    m = meet(a, b)
    not zero?(m) and not ideal?(m)
  end

  def ideal?(x) do
    zero?(wedge(x, new(e4: 1)))
  end

  def coincident?(a, b) do
    homogeneous_grade(a) == homogeneous_grade(b) and
      normalize(a) == normalize(b)
  end

  def direction(line) do
    meet(line, new(e4: 1))
  end

  def transform(motor, object) do
    gp(gp(motor, object), reverse(motor))
  end

  def point_coordinates(p) do
    w = coefficient(p, :e123)

    {
      coefficient(p, :e234) / w,
      -coefficient(p, :e134) / w,
      coefficient(p, :e124) / w
    }
  end

  def negate(x) do
    scale(-1, x)
  end

  def distance(a, b) do
    {ax, ay, az} = point_coordinates(a)
    {bx, by, bz} = point_coordinates(b)

    dx = ax - bx
    dy = ay - by
    dz = az - bz

    :math.sqrt(dx * dx + dy * dy + dz * dz)
  end

  def homogeneous_grade(x) do
    case grades(x) do
      [g] -> g
      [] -> nil
      _ -> nil
    end
  end

  def dot(a, b) do
    gp(a, b)
    |> scalar_part()
  end
end
