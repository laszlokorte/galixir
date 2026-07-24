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

  def normalize_point(p) do
    w = dot(p, e_o())

    if abs(w) < 1.0e-5 do
      dbg(p)
      raise ArgumentError, "cannot normalize point with zero weight"
    end

    scale(p, 1.0 / w)
  end

  def point?(p) do
    grades(p) == [1] and
      null?(p) and
      abs(dot(p, e_inf())) > 1.0e-10
  end

  defp null?(p) do
    n2 = abs(dot(p, p))

    scale =
      p.data
      |> Tuple.to_list()
      |> Enum.map(&abs/1)
      |> Enum.sum()

    n2 < 1.0e-12 * max(scale * scale, 1.0)
  end

  def circle?(c) do
    grades(c) == [3]
  end

  def line?(l) do
    grades(l) == [3] and
      coefficient(l, :e12pm) == 0
  end

  def point_pair?(x) do
    grades(x) == [2]
  end

  def circle_parameters(c) do
    v = gp(c, inverse(pseudoscalar()))

    e1 = coefficient(v, :e1)
    e2 = coefficient(v, :e2)

    ep = coefficient(v, :ep)
    em = coefficient(v, :em)

    w = em - ep

    if abs(w) < 1.0e-10 do
      {:line,
       {
         e1,
         e2,
         (em + ep) / 2
       }}
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

      {:circle, {{x, y}, r}}
    end
  end

  def split(o) do
    ei = e_inf()
    eo = e_o()

    nix = wedge(o, ei)

    nix2 = scalar_part(inner(nix, nix))

    if abs(nix2) < 1.0e-12 do
      :invalid
      # raise ArgumentError, "invalid point pair"
    else
      r2 =
        scalar_part(inner(o, o)) / nix2

      r = :math.sqrt(abs(r2))

      pos =
        o
        |> gp(inverse(nix))

      attitude =
        wedge(ei, eo)
        |> inner(nix)
        |> normalize()
        |> scale(r)

      kind =
        cond do
          r2 >= 0 ->
            :real

          true ->
            :imag
        end

      {
        kind,
        normalize_point(add(pos, attitude)),
        normalize_point(sub(pos, attitude))
      }
    end
  end

  def classify(x) do
    cond do
      point?(x) ->
        {:point, point_coordinates(x)}

      circle?(x) ->
        {:circle, circle_parameters(x)}

      line?(x) ->
        {:line, line_parameters(x)}

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

  def line_parameters(l) do
    {
      coefficient(l, :e12p),
      coefficient(l, :e12m),
      coefficient(l, :e1pm)
    }
  end
end
