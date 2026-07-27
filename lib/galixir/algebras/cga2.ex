defmodule Galixir.Algebras.CGA2 do
  @moduledoc """
  Two-dimensional Conformal Geometric Algebra (CGA).

  This module implements CGA for the Euclidean plane using the signature:

      {1, 1, 1, -1}

  with basis vectors:

      e1, e2, ep, em

  where `ep` and `em` are the positive and negative null-space basis
  used to construct the conformal origin and infinity vectors.

  The conformal basis is defined as:

      e_inf = e_m + e_p
       e_o = (e_m - e_p) / 2

  Points are embedded using the standard conformal embedding:

      P(x,y) = e_o + x*e1 + y*e2 + 1/2(x²+y²)e_inf

  Objects are represented as multivectors and can be combined using the
  operations provided by `Galixir.GeometricAlgebra`.

  ## Examples

      iex> p = Galixir.Algebras.CGA2.point(2, 3)
      iex> Galixir.Algebras.CGA2.point_coordinates(p)
      {2.0, 3.0}
  """
  use Galixir.GeometricAlgebra,
    signature: {1, 1, 1, -1},
    bases: {1, 2, :p, :m}

  @eps 1.0e-10

  @doc """
  Returns the zero multivector.
  """
  def zero do
    new()
  end

  @doc """
  Returns the scalar identity element.

  This is the multiplicative identity:

      1
  """
  def one do
    new(scalar: 1)
  end

  @doc """
  Returns the conformal infinity vector.

  The infinity vector represents the point at infinity in conformal space:

      e_inf = e_m + e_p
  """
  def e_inf do
    new(em: 1, ep: 1)
  end

  @doc """
  Returns the conformal origin vector.

  The origin is defined as:

      e_o = (e_m - e_p) / 2
  """
  def e_o do
    scale(
      0.5,
      add(
        new(em: 1),
        new(ep: -1)
      )
    )
  end

  @doc """
  Creates a Euclidean vector embedded in CGA.

  The vector is represented only by its Euclidean components:

      x*e1 + y*e2

  It is not a conformal point. Use `point/2` to embed a point.
  """
  def vector(x, y) do
    new(
      e1: x,
      e2: y
    )
  end

  @doc """
  Embeds a Euclidean point into conformal space.

  Uses the standard CGA point representation:

      P = e_o + x*e1 + y*e2 + 1/2(x²+y²)e_inf

  """
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

  @doc """
  Extracts Euclidean coordinates from a conformal point.

  Returns a tuple:

      {x, y}

  """
  def point_coordinates(p) do
    w = -dot(p, e_inf())

    {
      dot(p, new(e1: 1)) / w,
      dot(p, new(e2: 1)) / w
    }
  end

  @doc """
  Creates a circle from a center point and radius.

  The returned multivector represents the conformal circle object.
  """
  def circle(p, r) do
    sub(
      p,
      scale(
        0.5 * r * r,
        e_inf()
      )
    )
    |> gp(inverse(pseudoscalar()))
  end

  @doc """
  Creates a circle from Euclidean coordinates and radius.
  """
  def circle(x, y, r) do
    circle(point(x, y), r)
  end

  @doc """
  Creates a conformal line through two points.

  The line is represented using the outer product:

      L = a ∧ b ∧ e_inf
  """
  def line(a, b) do
    wedge(
      wedge(
        a,
        b
      ),
      e_inf()
    )
  end

  @doc """
  Creates a plane object from three points.

  In CGA2 this corresponds to the generalized line/circle construction
  obtained from three points and infinity.
  """
  def plane_from_points(a, b, c) do
    wedge(
      wedge(
        wedge(a, b),
        c
      ),
      e_inf()
    )
  end

  @doc """
  Tests whether a point lies on a conformal object.

  Returns `true` when the incidence meet operation produces the zero
  multivector.
  """
  def contains?(object, point) do
    zero?(meet(object, point))
  end

  @doc """
  Computes the meet (incidence) operation between two objects.

  Currently implemented as the outer product.
  """
  def meet(a, b) do
    wedge(
      gp(a, pseudoscalar()),
      gp(b, pseudoscalar())
    )
    |> gp(pseudoscalar())
  end

  @doc """
  Creates a translator motor for translating by `(x, y)`.

  The returned motor can be applied with `transform/2`.
  """
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

  @doc """
  Creates a Euclidean rotation rotor.

  Rotates by `angle` radians around the origin.
  """
  def rotor(angle) do
    add(
      new(scalar: :math.cos(angle / 2)),
      scale(
        -:math.sin(angle / 2),
        new(e12: 1)
      )
    )
  end

  @doc """
  Applies a motor transformation to a CGA object.

  Performs the sandwich product:

      M * X * reverse(M)
  """
  def transform(motor, object) do
    gp(
      gp(motor, object),
      reverse(motor)
    )
  end

  @doc """
  Computes the scalar product of two multivectors.

  This is the scalar part of the geometric product.
  """
  def dot(a, b) do
    scalar_part(gp(a, b))
  end

  @doc """
  Returns the CGA pseudoscalar:

      e1 ∧ e2 ∧ ep ∧ em
  """
  def pseudoscalar do
    new(e12pm: 1)
  end

  @doc """
  Normalizes a conformal point so that its weight is one.

  Raises `ArgumentError` if the point has zero weight.

  ## Examples

      iex> p = point(2, 3) |> scale(5)
      iex> normalized = normalize_point(p)
      iex> dot(normalized, e_o())
      1.0
  """
  def normalize_point(p) do
    w = dot(p, e_o())

    if abs(w) < @eps do
      raise ArgumentError, "cannot normalize point with zero weight"
    end

    scale(p, 1.0 / w)
  end

  @doc """
  Returns whether a multivector is a finite conformal point.

  A finite point is a grade-1 null vector with non-zero weight.

  ## Examples

      iex> point?(point(1, 2))
      true

      iex> point?(new(e1: 1, e2: 1))
      false
  """
  def point?(p) do
    grades(p) == [1] and
      null?(p) and
      abs(dot(p, e_o())) > @eps
  end

  @doc """
  Removes coefficients whose absolute value is below `eps`.

  This is useful for cleaning up floating-point round-off errors after
  geometric computations.

  ## Examples

      iex> new(e1: 1.0, e2: 1.0e-12)
      ...> |> cleanup()
      ...> |> coefficient(:e2)
      0.0
  """
  def cleanup(m, eps \\ @eps) do
    %__MODULE__{data: data} = m

    data =
      data
      |> Tuple.to_list()
      |> Enum.map(fn x ->
        if abs(x) < eps, do: 0.0, else: x
      end)
      |> List.to_tuple()

    %__MODULE__{data: data}
  end

  defp null?(p) do
    n2 = abs(dot(p, p))

    scale =
      p.data
      |> Tuple.to_list()
      |> Enum.map(&abs/1)
      |> Enum.sum()

    n2 < @eps * max(scale * scale, 1.0)
  end

  @doc """
  Returns whether a multivector is an OPNS circle.

  Lines are also represented by grade-3 blades, so `line?/1` should be
  used to distinguish between circles and lines.

  ## Examples

      iex> circle?(circle(point(0, 0), 2))
      true
  """
  def circle?(c) do
    grades(c) == [3]
  end

  @doc """
  Returns whether a multivector is an OPNS line.

  ## Examples

      iex> line?(line(point(0, 0), point(1, 0)))
      true

      iex> line?(circle(point(0, 0), 1))
      false
  """
  def line?(l) do
    grades(l) == [3] and
      norm(wedge(l, e_inf())) < @eps
  end

  @doc """
  Returns whether a multivector has the grade of a point pair.

  This function only checks the grade. Use `split/1` to determine whether
  the bivector represents a valid point pair.

  ## Examples

      iex> pp = meet(
      ...>   circle(point(0, 0), 2),
      ...>   line(point(-2, 0), point(2, 0))
      ...> )
      iex> point_pair?(pp)
      true
  """
  def point_pair?(x) do
    grades(x) == [2]
  end

  @doc """
  Extracts the Euclidean parameters of an OPNS circle or line.

  Returns either

    * `{:circle, {{x, y}, radius}}`
    * `{:line, {a, b, c}}`

  where the line satisfies `ax + by + c = 0`.

  ## Examples

      iex> circle_parameters(circle(point(1, 2), 3))
      {:circle, {{1.0, 2.0}, 3.0}}
  """
  def circle_parameters(c) do
    v = gp(c, inverse(pseudoscalar()))

    e1 = coefficient(v, :e1)
    e2 = coefficient(v, :e2)

    ep = coefficient(v, :ep)
    em = coefficient(v, :em)

    w = em - ep

    if norm(wedge(c, e_inf())) < @eps do
      {:line, line_parameters(c)}
    else
      x = e1 / w
      y = e2 / w

      k = (em + ep) / (2 * w)

      r =
        :math.sqrt(
          x * x +
            y * y -
            2 * k
        )

      {:circle, {{clean_zero(x), clean_zero(y)}, r}}
    end
  end

  @doc """
  Splits a point pair into its two conformal points.

  Returns

  * `{:real, p1, p2}` for two real points,
  * `{:imag, p1, p2}` for an imaginary point pair, or
  * `:invalid` if the bivector is not a valid point pair.

  ## Examples

  iex> l = line(point(-2, 0), point(2, 0))
  iex> c = circle(point(0, 0), 1)
  iex> {:real, p1, p2} = split(meet(c, l))
  iex> Enum.sort([point_coordinates(p1), point_coordinates(p2)])
  [{-1.0, 0.0}, {1.0, 0.0}]

  iex> c1 = circle(point(-0.5, 0), 1)
  iex> c2 = circle(point(0.5, 0), 1)
  iex> {:real, p1, p2} = split(meet(c1, c2))
  iex> [{x1, y1}, {x2, y2}] = Enum.sort([point_coordinates(p1), point_coordinates(p2)])
  iex> abs(x1) < 1.0e-10 and abs(x2) < 1.0e-10
  true
  iex> (y1 < 0) != (y2 < 0)
  true
  iex> abs(abs(y1) - :math.sqrt(0.75)) < 1.0e-10
  true
  iex> abs(abs(y2) - :math.sqrt(0.75)) < 1.0e-10
  true
  """
  def split(o) do
    ei = e_inf()
    eo = e_o()

    nix = wedge(o, ei)

    nix2 = scalar_part(inner(nix, nix))

    if abs(nix2) < @eps do
      :invalid
    else
      r2 = scalar_part(inner(o, o)) / nix2

      r = :math.sqrt(abs(r2))

      pos = o |> gp(inverse(nix))

      attitude =
        wedge(ei, eo)
        |> inner(nix)
        |> normalize()
        |> scale(r)

      kind = if(r2 >= 0, do: :real, else: :imag)

      {
        kind,
        normalize_point(add(pos, attitude)),
        normalize_point(sub(pos, attitude))
      }
    end
  end

  @doc """
  Classifies a geometric object and extracts its Euclidean parameters.

  Returns one of

    * `{:point, {x, y}}`
    * `{:line, {a, b, c}}`
    * `{:circle, {{x, y}, radius}}`
    * `{:point_pair, kind, {p1, p2}}`
    * `{:unknown, multivector}`

  ## Examples

      iex> classify(point(2, 3))
      {:point, {2.0, 3.0}}

      iex> classify(point(2, 3))
      {:point, {2.0, 3.0}}

      iex> classify(point(-5, 4))
      {:point, {-5.0, 4.0}}

      iex> {:line, {a, b, c}} = classify(line(point(0, 0), point(0, 1)))
      iex> abs(a) == 1.0 and b == 0.0 and c == 0.0
      true

      iex> {:line, {a, b, c}} = classify(line(point(0, 0), point(1, 0)))
      iex> a == 0.0 and abs(b) == 1.0 and c == 0.0
      true

      iex> classify(circle(point(0, 0), 2))
      {:circle, {{0.0, 0.0}, 2.0}}

      iex> classify(circle(point(3, -2), 5))
      {:circle, {{3.0, -2.0}, 5.0}}

      iex> pp =
      ...>   meet(
      ...>     circle(point(0, 0), 2),
      ...>     line(point(-3, 0), point(3, 0))
      ...>   )
      iex> {:point_pair, :real, points} = classify(pp)
      iex> Enum.sort(Tuple.to_list(points))
      [{-2.0, 0.0}, {2.0, 0.0}]

      iex> pp =
      ...>   meet(
      ...>     circle(point(0, 0), 1),
      ...>     line(point(-2, 0), point(2, 0))
      ...>   )
      iex> match?({:point_pair, :real, _}, classify(pp))
      true

      iex> classify(new(e1: 1))
      {:unknown, new(e1: 1)}
  """
  def classify(x) do
    cond do
      point?(x) ->
        {:point, point_coordinates(x)}

      line?(x) ->
        {:line, line_parameters(x)}

      circle?(x) ->
        circle_parameters(x)
        |> case do
          {:circle, c} -> {:circle, c}
          {:line, l} -> {:line, l}
        end

      point_pair?(x) ->
        split(x)
        |> case do
          {kind, p1, p2} ->
            {
              :point_pair,
              kind,
              {point_coordinates(p1), point_coordinates(p2)}
            }

          :invalid ->
            {:unknown, x}
        end

      true ->
        {:unknown, x}
    end
  end

  @doc """
  Returns the Euclidean coefficients of an OPNS line.

  The returned tuple `{a, b, c}` satisfies

      ax + by + c = 0

  ## Examples

    iex> {a, b, c} = line_parameters(line(point(0, 0), point(0, 1)))
    iex> {abs(a), b, c}
    {1.0, 0.0, 0.0}
  """
  def line_parameters(l) do
    l = dual(l)

    {
      dot(l, new(e1: 1)),
      dot(l, new(e2: 1)),
      dot(l, e_o())
    }
  end

  # handle IEEE-754 negative zero
  defp clean_zero(x) when x == 0.0, do: 0.0
  defp clean_zero(x), do: x
end
