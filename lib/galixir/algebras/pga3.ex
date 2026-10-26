defmodule Galixir.Algebras.PGA3 do
  use Galixir.Algebras.Models.PGA, dimensions: {"x", "y", "z"}

  @doc "Applies a normalized motor using its reverse in the sandwich product."
  def transform(object, motor), do: gp(gp(motor, object), reverse(motor))

  @doc """
  Creates a line through two points (a grade-2 blade).

      iex> grade(line(point(0, 0, 0), point(1, 0, 0)))
      2
  """
  def line(a, b), do: join(a, b)

  @doc """
  Creates a plane `ax + by + cz + d = 0` (a grade-1 blade).

      iex> incident?(plane(0, 0, 1, -3), point(1, 2, 3))
      true
  """
  def plane(a, b, c, d), do: new(e1: a, e2: b, e3: c, e0: d)

  @doc "Creates a plane from a Euclidean normal vector and a finite point."
  def plane_from_normal_point(n, p) do
    n = normalize!(n)
    {x, y, z} = point_coordinates(p)
    a = coefficient(n, :e1)
    b = coefficient(n, :e2)
    c = coefficient(n, :e3)
    plane(a, b, c, -(a * x + b * y + c * z))
  end

  @doc "Returns the Euclidean normal vector of a plane."
  def plane_normal(p), do: vector(coefficient(p, :e1), coefficient(p, :e2), coefficient(p, :e3))

  @doc "Returns the normalized normal vector of a plane."
  def normalized_plane_normal(p), do: normalize!(plane_normal(p))

  @doc """
  Checks whether a line lies entirely at infinity.

      iex> ideal_line?(line(ideal_point(1, 0, 0), ideal_point(0, 1, 0)))
      true
      iex> ideal_line?(line(point(0, 0, 0), point(1, 0, 0)))
      false
  """
  def ideal_line?(l), do: grade?(l, 2) and zero?(wedge(l, new(e0: 1)))

  @doc "Checks whether two lines have the same direction (including identical lines)."
  def parallel?(line_a, line_b), do: coincident?(direction_point(line_a), direction_point(line_b))

  @doc "Returns the ideal point representing the direction of a line."
  def direction_point(line), do: meet(line, new(e0: 1))

  @doc """
  Returns the Euclidean direction vector of a line.

      iex> direction_vector(line(point(1, 2, 3), point(2, 3, 4)))
      new(e1: 1, e2: 1, e3: 1)
  """
  def direction_vector(line) do
    d = direction_point(line)
    vector(coefficient(d, :e032), coefficient(d, :e013), coefficient(d, :e021))
  end

  @doc "Returns the normalized direction vector of a line."
  def normalized_direction_vector(line), do: normalize!(direction_vector(line))

  @doc """
  Creates a rotation motor about a line axis.

      iex> axis = line(point(0, 0, 0), point(0, 0, 1))
      iex> {x, y, z} = point_coordinates(transform(point(1, 0, 0), rotor(axis, :math.pi() / 2)))
      iex> {Float.round(x, 10), Float.round(y, 10), Float.round(z, 10)}
      {0.0, 1.0, 0.0}
  """
  def rotor(line_axis, angle) do
    line_axis = normalize_line(line_axis)

    add(new(scalar: :math.cos(angle / 2)), scale(:math.sin(angle / 2), line_axis))
    |> normalize!()
  end

  @doc """
  Normalizes a line used as a rotation axis. Raises for a null line.

      iex> n = normalize_line(line(point(0, 0, 0), point(0, 0, 1)))
      iex> scalar_part(gp(n, n))
      -1.0
  """
  def normalize_line(line) do
    n = gp(line, reverse(line)) |> scalar_part() |> abs() |> then(&(&1 ** 0.5))
    if not above_epsilon?(n), do: raise(ArgumentError, "cannot normalize null line")
    scale(1 / n, line)
  end

  @doc """
  Computes a motor aligning corresponding finite or ideal points.
  An empty list returns the identity motor. Lines and planes are not direct constraints.

      iex> align([], []) == one()
      true
      iex> point_coordinates(transform(origin(), align([origin()], [point(1, 2, 3)])))
      {1.0, 2.0, 3.0}

      iex> from = [point(0, 0, 0), point(1, 0, 0)]
      iex> to = [point(0, 0, 0), point(0, 1, 0)]
      iex> point_coordinates(transform(point(1, 0, 0), align(from, to)))
      {0.0, 1.0, 0.0}

      iex> from = [point(0, 0, 0), point(1, 0, 0), point(0, 1, 0)]
      iex> to = [point(1, 2, 3), point(1, 3, 3), point(0, 2, 3)]
      iex> point_coordinates(transform(point(1, 0, 0), align(from, to)))
      {1.0, 3.0, 3.0}

      iex> align([origin()], [])
      ** (ArgumentError) cannot align different numbers of objects
  """
  def align([], []), do: one()

  def align(as, bs) when length(as) != length(bs) do
    raise ArgumentError, "cannot align different numbers of objects"
  end

  def align(ps, qs) do
    identity = one()
    initial_q = hodge_dual(identity)

    Enum.zip_reduce(ps, qs, {identity, initial_q}, fn p, q, {m, prev_q} ->
      p = prev_q |> join(transform(p, m)) |> normalize!()
      new_q = prev_q |> join(q) |> normalize!() |> inverse!()
      new_m = new_q |> gp(p) |> add(identity) |> gp(m)
      {new_m, new_q}
    end)
    |> elem(0)
  end

  @doc "Computes the logarithm of a motor."
  def motor_log(mot), do: scale(grade(mot, 2), 1 / coefficient(mot, :scalar))

  @doc """
  Computes the exponential of a bivector motor logarithm.

      iex> t = translator(5, 0, 0)
      iex> motor_exp(motor_log(t)) |> normalize!() == normalize!(t)
      true
  """
  def motor_exp(bv) do
    bv2 = gp(bv, bv)
    bv4 = grade(bv2, 4)
    numerator = add(add(one(), bv), scale(bv4, 0.5))
    denominator = 1 - coefficient(bv2, :scalar)
    scale(numerator, 1 / denominator) |> normalize!()
  end

  @doc """
  Raises a motor to a scalar power for interpolation.

      iex> point_coordinates(transform(origin(), motor_pow(translator(10, 0, 0), 0.5)))
      {5.0, 0.0, 0.0}
  """
  def motor_pow(motor, t), do: motor |> motor_log() |> scale(t) |> motor_exp()
end
