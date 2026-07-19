defmodule Galixir.Algebras.PGA3 do
  use Galixir.GeometricAlgebra, signature: {1, 1, 1, 0}, bases: {1, 2, 3, 0}

  def zero do
    new()
  end

  def one() do
    new(scalar: 1)
  end

  def origin do
    point(0, 0, 0)
  end

  def ideal_point?(p) do
    homogeneous_grade(p) == 3 and
      coefficient(p, :e123) == 0
  end

  def finite_point?(p) do
    homogeneous_grade(p) == 3 and
      coefficient(p, :e123) != 0
  end

  def point(x, y, z) do
    new(
      e123: 1,
      e032: x,
      e013: y,
      e021: z
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
      e0: d
    )
  end

  def plane_from_normal_point(n, p) do
    n = normalize(n)
    {x, y, z} = point_coordinates(p)

    a = coefficient(n, :e1)
    b = coefficient(n, :e2)
    c = coefficient(n, :e3)

    plane(
      a,
      b,
      c,
      -(a * x + b * y + c * z)
    )
  end

  def plane_normal(p) do
    vector(
      coefficient(p, :e1),
      coefficient(p, :e2),
      coefficient(p, :e3)
    )
  end

  def unit_plane_normal(p) do
    normalize(plane_normal(p))
  end

  def translator(v) do
    new(
      scalar: 1,
      e01: coefficient(v, :e1) / 2,
      e02: coefficient(v, :e2) / 2,
      e03: coefficient(v, :e3) / 2
    )
  end

  def translator(x, y, z) do
    new(
      scalar: 1,
      e01: x / 2,
      e02: y / 2,
      e03: z / 2
    )
  end

  def rotation_between_vectors(a, b) do
    a = normalize(a)
    b = normalize(b)

    s = 1 + scalar_part(gp(a, b))

    if s < 1.0e-8 do
      raise "opposite vectors need special handling, given (#{inspect(a)}) and (#{inspect(b)})"
    end

    r =
      add(
        new(scalar: 1),
        gp(b, a)
      )

    normalize(r)
  end

  def rotor(line_axis, angle) do
    line_axis = normalize_line(line_axis)

    add(
      new(scalar: :math.cos(angle / 2)),
      scale(
        -:math.sin(angle / 2),
        line_axis
      )
    )
    |> normalize()
  end

  def normalize_line(line) do
    d = ideal_direction(line)

    n =
      gp(d, reverse(d))
      |> scalar_part()
      |> :math.sqrt()

    scale(1 / n, line)
  end

  def direction_between_points(p, q) do
    d = sub(q, p)

    vector(
      coefficient(d, :e230),
      coefficient(d, :e013),
      coefficient(d, :e120)
    )
  end

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

  def parallel?(a, b) do
    ideal?(meet(a, b))
  end

  def intersects?(a, b) do
    m = meet(a, b)
    not zero?(m) and not ideal?(m)
  end

  def ideal?(x) do
    zero?(wedge(x, new(e0: 1)))
  end

  def coincident?(a, b) do
    homogeneous_grade(a) == homogeneous_grade(b) and
      zero?(sub(canonicalize(a), canonicalize(b)))
  end

  def ideal_direction(line) do
    meet(line, new(e0: 1))
  end

  def direction_vector(line) do
    d = ideal_direction(line)

    vector(
      coefficient(d, :e230),
      coefficient(d, :e013),
      coefficient(d, :e120)
    )
  end

  def unit_direction_vector(line) do
    normalize(direction_vector(line))
  end

  def transform(motor, object) do
    gp(gp(motor, object), inverse(motor))
  end

  def ideal_point(x, y, z) do
    new(
      e032: x,
      e013: y,
      e021: z
    )
  end

  def point_coordinates(p) do
    w = coefficient(p, :e123)

    {
      coefficient(p, :e032) / w,
      coefficient(p, :e013) / w,
      coefficient(p, :e021) / w
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
    gp(a, b) |> scalar_part()
  end

  def align(ps, qs) do
    # https://observablehq.com/@enkimute/glu-lookat-in-3d-pga
    initial_m = one = new(scalar: 1)
    initial_q = dual(new(scalar: 1))

    Enum.zip_reduce(ps, qs, {initial_m, initial_q}, fn p, q, {m, prev_q} ->
      p = prev_q |> join(transform(m, p)) |> normalize()
      new_q = prev_q |> join(q) |> normalize() |> blade_inverse()
      new_m = new_q |> gp(p) |> add(one) |> gp(m)

      {new_m, new_q}
    end)
    |> elem(0)
  end

  def motor_log(mot) do
    scale(
      grade(mot, 2),
      1 / coefficient(mot, :scalar)
    )
  end

  def motor_exp(bv) do
    bv2 = gp(bv, bv)
    bv4 = grade(bv2, 4)

    numerator =
      add(
        add(
          new(scalar: 1),
          bv
        ),
        scale(bv4, 0.5)
      )

    denominator =
      1 - coefficient(bv2, :scalar)

    scale(numerator, 1 / denominator)
    |> normalize()
  end

  def motor_pow(motor, t) do
    motor
    |> motor_log()
    |> scale(t)
    |> motor_exp()
  end
end
