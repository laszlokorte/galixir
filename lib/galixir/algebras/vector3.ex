defmodule Galixir.Algebras.Vector3 do
  @moduledoc """
  Three-dimensional Euclidean geometric algebra, `Cl(3, 0)`.

  This is a classic, non-projective vector algebra: grade-1 multivectors are
  ordinary Cartesian vectors. Its metric is `{1, 1, 1}` and its basis is
  `e1`, `e2`, `e3`.

      v = x*e1 + y*e2 + z*e3

  Bivectors represent oriented planes and generate rotations. The
  pseudoscalar `e123` dualizes vectors and bivectors, which makes the familiar
  three-dimensional cross product available.

  ## Examples

      iex> cross(vector(1, 0, 0), vector(0, 1, 0)) |> coordinates()
      {0.0, 0.0, 1.0}
  """

  use Galixir.GeometricAlgebra,
    metric: {1, 1, 1},
    bases: {"1", "2", "3"}

  @doc """
  Returns the additive identity.

  ## Examples

      iex> zero()
      new()
  """
  def zero, do: new()

  @doc """
  Returns the multiplicative scalar identity.

  ## Examples

      iex> one()
      new(scalar: 1)
  """
  def one, do: new(scalar: 1)

  @doc """
  Returns the unit pseudoscalar, the oriented volume element `e123`.

  ## Examples

      iex> pseudoscalar()
      new(e123: 1)
  """
  def pseudoscalar, do: new(e123: 1)

  @doc """
  Creates the Cartesian vector `x*e1 + y*e2 + z*e3`.

  ## Examples

      iex> vector(1, 2, -3)
      new(e1: 1, e2: 2, e3: -3)
  """
  def vector(x, y, z), do: new(e1: x, e2: y, e3: z)

  @doc """
  Extracts the Cartesian coordinates of a vector.

  ## Examples

      iex> coordinates(vector(1, 2, -3))
      {1.0, 2.0, -3.0}
  """
  def coordinates(v), do: {coefficient(v, :e1), coefficient(v, :e2), coefficient(v, :e3)}

  @doc """
  Checks whether a multivector is a vector (a pure grade-1 multivector).

  ## Examples

      iex> vector?(vector(1, 2, 3))
      true

      iex> vector?(pseudoscalar())
      false
  """
  def vector?(v), do: grade?(v, 1)

  @doc """
  Computes the Euclidean scalar product of two vectors.

  ## Examples

      iex> scalar_product(vector(1, 2, 3), vector(4, 5, 6))
      32.0
  """
  def scalar_product(a, b), do: scalar_part(gp(a, b))

  @doc """
  Computes the squared Euclidean length of a vector.

  ## Examples

      iex> squared_length(vector(2, 3, 6))
      49.0
  """
  def squared_length(v), do: scalar_product(v, v)

  @doc """
  Computes the Euclidean length of a vector.

  ## Examples

      iex> len(vector(2, 3, 6))
      7.0
  """
  def len(v), do: :math.sqrt(squared_length(v))

  @doc """
  Normalizes a non-zero vector to unit length.

  Raises `ArgumentError` for the zero vector.

  ## Examples

      iex> normal(vector(2, 0, 0)) |> coordinates()
      {1.0, 0.0, 0.0}
  """
  def normal(v), do: normalize(v)

  @doc """
  Computes the vector cross product of two vectors.

  It is the negative pseudoscalar dual of the outer product:

      a × b = -(a ∧ b) * e123

  ## Examples

      iex> cross(vector(1, 0, 0), vector(0, 1, 0))
      new(e3: 1)
  """
  def cross(a, b), do: negate(gp(wedge(a, b), pseudoscalar()))

  @doc """
  Returns the unsigned angle between two non-zero vectors, in radians.

  ## Examples

      iex> angle(vector(1, 0, 0), vector(0, 1, 0))
      :math.pi() / 2
  """
  def angle(a, b) do
    cosine = scalar_product(a, b) / (len(a) * len(b))
    :math.acos(min(1.0, max(-1.0, cosine)))
  end

  @doc """
  Projects vector `v` onto a non-zero vector `onto`.

  ## Examples

      iex> project(vector(3, 4, 5), vector(1, 0, 0)) |> coordinates()
      {3.0, 0.0, 0.0}
  """
  def project(v, onto) do
    scale(scalar_product(v, onto) / squared_length(onto), onto)
  end

  @doc """
  Returns the component of `v` perpendicular to `onto`.

  ## Examples

      iex> reject(vector(3, 4, 5), vector(1, 0, 0)) |> coordinates()
      {0.0, 4.0, 5.0}
  """
  def reject(v, onto), do: sub(v, project(v, onto))

  @doc """
  Computes the Euclidean distance between two vectors interpreted as points.

  ## Examples

      iex> distance(vector(1, 2, 3), vector(4, 6, 3))
      5.0
  """
  def distance(a, b), do: len(sub(a, b))

  @doc """
  Creates an oriented bivector from its `xy`, `yz`, and `zx` components.

      B = xy*e12 + yz*e23 + zx*e31

  ## Examples

      iex> bivector(1, 2, 3)
      new(e12: 1, e23: 2, e31: 3)
  """
  def bivector(xy, yz, zx), do: new(e12: xy, e23: yz, e31: zx)

  @doc """
  Extracts the `xy`, `yz`, and `zx` components of a bivector.

  ## Examples

      iex> bivector_coordinates(bivector(1, 2, 3))
      {1.0, 2.0, 3.0}
  """
  def bivector_coordinates(b),
    do: {coefficient(b, :e12), coefficient(b, :e23), coefficient(b, :e31)}

  @doc """
  Returns the XY plane bivector `e12`.

  ## Examples

      iex> bivector_xy()
      new(e12: 1)
  """
  def bivector_xy, do: bivector(1, 0, 0)

  @doc """
  Returns the YZ plane bivector `e23`.

  ## Examples

      iex> bivector_yz()
      new(e23: 1)
  """
  def bivector_yz, do: bivector(0, 1, 0)

  @doc """
  Returns the ZX plane bivector `e31`.

  ## Examples

      iex> bivector_zx()
      new(e31: 1)
  """
  def bivector_zx, do: bivector(0, 0, 1)

  @doc """
  Creates a rotor around non-zero vector `axis` by `angle` radians.

  Positive angles follow the right-hand rule around the axis.

  ## Examples

      iex> rotate(rotor(vector(0, 0, 1), :math.pi() / 2), vector(1, 0, 0)) |> coordinates() |> Tuple.to_list() |> Enum.map(&Float.round(&1, 12))
      [0.0, 1.0, 0.0]
  """
  def rotor(axis, angle) do
    plane = axis |> normal() |> dual()
    add(new(scalar: :math.cos(angle / 2)), scale(-:math.sin(angle / 2), plane))
  end

  @doc """
  Rotates a vector or multivector with rotor `r`.

  Applies the sandwich product `R*v*reverse(R)`.

  ## Examples

      iex> rotate(rotor(vector(0, 0, 1), :math.pi()), vector(1, 0, 0)) |> coordinates() |> Tuple.to_list() |> Enum.map(&Float.round(&1, 12))
      [-1.0, 0.0, 0.0]
  """
  def rotate(r, v), do: gp(gp(r, v), reverse(r))

  @doc """
  Reflects `v` in the plane whose normal is non-zero vector `n`.

  ## Examples

      iex> reflect(vector(1, 2, 3), vector(0, 0, 1)) |> coordinates()
      {1.0, 2.0, -3.0}
  """
  def reflect(v, n), do: negate(gp(gp(n, v), inverse(n)))

  @doc """
  Negates every component of a multivector.

  ## Examples

      iex> negate(vector(1, -2, 3))
      new(e1: -1, e2: 2, e3: -3)
  """
  def negate(x), do: scale(-1, x)
end
