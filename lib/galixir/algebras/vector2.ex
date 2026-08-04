defmodule Galixir.Algebras.Vector2 do
  @moduledoc """
  Two-dimensional Euclidean geometric algebra, `Cl(2, 0)`.

  This is a classic, non-projective vector algebra: grade-1 multivectors are
  ordinary Cartesian vectors, not homogeneous points or directions. Its metric
  is `{1, 1}` and its basis is `e1`, `e2`.

      v = x*e1 + y*e2

  The unit pseudoscalar `e12` is the oriented plane. It represents oriented
  areas and generates rotations.

  ## Examples

      iex> vector(3, 4) |> len()
      5.0

      iex> rotate(rotor(:math.pi() / 2), vector(1, 0))
      ...> |> coordinates()
      ...> |> Tuple.to_list()
      ...> |> Enum.map(&Float.round(&1, 12))
      [0.0, 1.0]
  """

  use Galixir.GeometricAlgebra,
    metric: {1, 1},
    bases: {"1", "2"}

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
  Returns the unit pseudoscalar, the oriented plane `e12`.

  ## Examples

      iex> pseudoscalar()
      new(e12: 1)
  """
  def pseudoscalar, do: new(e12: 1)

  @doc """
  Creates the Cartesian vector `x*e1 + y*e2`.

  ## Examples

      iex> vector(2, -3)
      new(e1: 2, e2: -3)
  """
  def vector(x, y), do: new(e1: x, e2: y)

  @doc """
  Extracts the Cartesian coordinates of a vector.

  ## Examples

      iex> coordinates(vector(2, -3))
      {2.0, -3.0}
  """
  def coordinates(v), do: {coefficient(v, :e1), coefficient(v, :e2)}

  @doc """
  Creates an oriented plane bivector `area*e12`.

  ## Examples

      iex> bivector(2)
      new(e12: 2)
  """
  def bivector(area), do: new(e12: area)

  @doc """
  Checks whether a multivector is a vector (a pure grade-1 multivector).

  ## Examples

      iex> vector?(vector(1, 2))
      true

      iex> vector?(one())
      false
  """
  def vector?(v), do: grade?(v, 1)

  @doc """
  Computes the Euclidean scalar product of two vectors.

  ## Examples

      iex> scalar_product(vector(1, 2), vector(3, 4))
      11.0
  """
  def scalar_product(a, b), do: scalar_part(gp(a, b))

  @doc """
  Computes the squared Euclidean length of a vector.

  ## Examples

      iex> squared_length(vector(3, 4))
      25.0
  """
  def squared_length(v), do: scalar_product(v, v)

  @doc """
  Computes the Euclidean length of a vector.

  ## Examples

      iex> len(vector(3, 4))
      5.0
  """
  def len(v), do: squared_length(v) ** 0.5

  @doc """
  Normalizes a non-zero vector to unit length.

  Raises `ArgumentError` for the zero vector.

  ## Examples

      iex> normal(vector(3, 4)) |> coordinates() |> Tuple.to_list() |> Enum.map(&Float.round(&1, 12))
      [0.6, 0.8]
  """
  def normal(v), do: normalize(v)

  @doc """
  Computes the signed two-dimensional cross product of two vectors.

  The result is the `e12` coefficient of `a ∧ b`; its sign gives the
  orientation from `a` to `b`.

  ## Examples

      iex> cross(vector(1, 0), vector(0, 1))
      1.0
  """
  def cross(a, b), do: coefficient(wedge(a, b), :e12)

  @doc """
  Returns the signed angle from vector `a` to vector `b`, in radians.

  Positive angles are counter-clockwise.

  ## Examples

      iex> angle(vector(1, 0), vector(0, 1))
      :math.pi() / 2
  """
  def angle(a, b), do: :math.atan2(cross(a, b), scalar_product(a, b))

  @doc """
  Projects vector `v` onto a non-zero vector `onto`.

  ## Examples

      iex> project(vector(3, 4), vector(1, 0)) |> coordinates()
      {3.0, 0.0}
  """
  def project(v, onto) do
    scale(scalar_product(v, onto) / squared_length(onto), onto)
  end

  @doc """
  Returns the component of `v` perpendicular to `onto`.

  ## Examples

      iex> reject(vector(3, 4), vector(1, 0)) |> coordinates()
      {0.0, 4.0}
  """
  def reject(v, onto), do: sub(v, project(v, onto))

  @doc """
  Computes the Euclidean distance between two vectors interpreted as points.

  ## Examples

      iex> distance(vector(1, 2), vector(4, 6))
      5.0
  """
  def distance(a, b), do: len(sub(a, b))

  @doc """
  Creates a rotor for a counter-clockwise rotation by `angle` radians.

      R = cos(angle / 2) - e12*sin(angle / 2)

  ## Examples

      iex> rotor(:math.pi()) |> coefficient(:e12) |> Float.round(12)
      -1.0
  """
  def rotor(angle) do
    new(scalar: :math.cos(angle / 2), e12: -:math.sin(angle / 2))
  end

  @doc """
  Rotates a vector or multivector with rotor `r`.

  Applies the sandwich product `R*v*reverse(R)`.

  ## Examples

      iex> rotate(rotor(:math.pi() / 2), vector(1, 0)) |> coordinates() |> Tuple.to_list() |> Enum.map(&Float.round(&1, 12))
      [0.0, 1.0]
  """
  def rotate(r, v), do: gp(gp(r, v), reverse(r))

  @doc """
  Reflects `v` in the line whose normal is non-zero vector `n`.

  ## Examples

      iex> reflect(vector(1, 2), vector(0, 1)) |> coordinates()
      {1.0, -2.0}
  """
  def reflect(v, n), do: negate(gp(gp(n, v), inverse(n)))

  @doc """
  Returns the vector perpendicular to `v` after a counter-clockwise quarter turn.

  ## Examples

      iex> perpendicular(vector(2, 3)) |> coordinates() |> Tuple.to_list() |> Enum.map(&Float.round(&1, 12))
      [-3.0, 2.0]
  """
  def perpendicular(v), do: rotate(rotor(:math.pi() / 2), v)

  @doc """
  Negates every component of a multivector.

  ## Examples

      iex> negate(vector(1, -2))
      new(e1: -1, e2: 2)
  """
  def negate(x), do: scale(-1, x)
end
