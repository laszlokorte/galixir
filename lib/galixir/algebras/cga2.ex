defmodule Galixir.Algebras.CGA2 do
  use Galixir.Algebras.Models.CGA, dimensions: {"x", "y"}

  @doc """
  Creates a circle from a center point and radius.

  The returned multivector represents the conformal circle object.

  ## Examples

      iex> circle(1, 2, 3)
      ~G"1.5e12p + 2.5e12m + 2.0e1pm - e2pm"

      iex> circle?(circle(1, 2, 3))
      true

      iex> circle_parameters(circle(1, 2, 3))
      {:circle, {:real, {1.0, 2.0}, 3.0}}

      iex> circle_parameters(circle(1, 2, -3))
      {:circle, {:imag, {1.0, 2.0}, 3.0}}

      iex> c = circle(point(1, 2), 3)
      iex> contains?(c, point(4, 2))
      true
      iex> contains?(c, point(5, 2))
      false
  """
  def circle(p, r) do
    sub(
      p,
      scale(
        0.5 * r * abs(r),
        e_inf()
      )
    )
    |> gp(inverse!(pseudoscalar()))
  end

  @doc """
  Creates an OPNS circle or degenerate line through three conformal points.

  The circle is represented by the outer product:

      `C = a ∧ b ∧ c`

  For collinear points this degenerates to a line.

  ## Examples

      iex> c =
      ...>   line_or_circle_from_points(
      ...>     point(1, 0),
      ...>     point(0, 1),
      ...>     point(-1, 0)
      ...>   )
      iex> circle?(c)
      true
      iex> circle_parameters(c)
      {:circle, {:real, {0.0, 0.0}, 1.0}}

      iex> c =
      ...>   line_or_circle_from_points(
      ...>     point(0, 0),
      ...>     point(1, 0),
      ...>     point(0, 1)
      ...>   )
      iex> contains?(c, point(0, 0))
      true

      iex> c =
      ...>   line_or_circle_from_points(
      ...>     point(0, 0),
      ...>     point(1, 0),
      ...>     point(2, 0)
      ...>   )
      iex> line?(c)
      true
  """
  def line_or_circle_from_points(a, b, c) do
    join(a, b, c)
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

      `L = a ∧ b ∧ e_inf`

  ## Examples

      iex> line?(line(point(0, 0), point(1, 0)))
      true

      iex> contains?(line(point(0, 0), point(1, 0)), point(0.5, 0))
      true

      iex> l = line(point(0, 0), point(1, 0))
      iex> line?(l)
      true

      iex> contains?(line(point(0, 0), point(1, 0)), point(2, 0))
      true

      iex> contains?(line(point(0, 0), point(1, 0)), point(0, 1))
      false

      iex> l = line(point(2, -1), point(2, 3))
      iex> contains?(l, point(2, 10))
      true
      iex> contains?(l, point(3, 0))
      false
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
  Tests whether a point lies on a conformal object.

  Returns `true` when the incidence meet operation produces the zero
  multivector.

  ## Examples

      iex> l = line(point(0, 0), point(1, 0))
      iex> contains?(l, point(2, 0))
      true
      iex> contains?(l, point(0, 1))
      false
  """
  def contains?(object, point) do
    zero?(meet(object, point))
  end

  @doc """
  Computes the meet (incidence) operation between two objects.

  The meet is implemented using duality:

    `meet(a, b) = dual(dual(a) ∧ dual(b))`

  ## Examples

      iex> l = line(point(-2, 0), point(2, 0))
      iex> c = circle(point(0, 0), 1)
      iex> bivector_candidate?(meet(c, l))
      true

      iex> c1 = circle(point(1, 2), 1)
      iex> c2 = circle(point(3, 2), 1)
      iex> {:tangent, p} = split(meet(c1, c2) )
      iex> p |> point_coordinates()
      {2.0, 2.0}

      iex> c1 = circle(point(1, -1), 1)
      iex> c2 = circle(point(1, -3), 1)
      iex> {:tangent, p} = split(meet(c1, c2))
      iex> p |> point_coordinates()
      {1.0, -2.0}

      iex> pp =
      ...>   meet(
      ...>     circle(point(0, 0), 1),
      ...>     circle(point(5, 0), 1)
      ...>   )
      iex> match?({:point_pair, _, _}, classify(pp))
      true
  """
  def meet(a, b) do
    wedge(
      gp(a, pseudoscalar()),
      gp(b, pseudoscalar())
    )
    |> gp(pseudoscalar())
  end

  @doc """
  Creates a Euclidean rotation rotor.

  Rotates by `angle` radians around the origin.

  The rotor is normalized before being returned.

  ## Examples

      iex> {x, y} = point(1, 0)
      ...> |> transform(rotor(:math.pi() / 2))
      ...> |> cleanup()
      ...> |> point_coordinates()
      iex> abs(x) < 1.0e-10
      true
      iex> abs(y - 1.0) < 1.0e-10
      true
  """
  def rotor(angle) do
    add(
      new(scalar: :math.cos(angle / 2)),
      scale(
        -:math.sin(angle / 2),
        new(e12: 1)
      )
    )
    |> normalize!()
  end

  @doc """
  Returns whether a multivector is an OPNS circle or line.

  In CGA2 both circles and lines are grade-3 objects.
  Lines are exactly those trivectors containing e_inf.

  Use `line?/1` to distinguish lines.

  ## Examples

      iex> circle_or_line?(circle(point(0, 0), 2))
      true
  """
  def circle_or_line?(c) do
    grade?(c, 3)
  end

  @doc """
  Returns whether a multivector represents an OPNS circle.

  Lines are also grade-3 blades in CGA2, so they are excluded.

  ## Examples

      iex> circle?(circle(point(0, 0), 2))
      true

      iex> circle?(line(point(0, 0), point(1, 0)))
      false
  """
  def circle?(x) do
    circle_or_line?(x) and not line?(x)
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
    grade?(l, 3) and
      not above_epsilon?(norm(wedge(l, e_inf())))
  end

  @doc """
  Returns true for a grade-2 bivector whose outer product with `e_inf` has
  norm above `epsilon()`. This is only a candidate check, not a guarantee of
  finite real intersection points. Use `split/1` to inspect the result.

  ## Examples

      iex> pp = meet(
      ...>   circle(point(0, 0), 2),
      ...>   line(point(-2, 0), point(2, 0))
      ...> )
      iex> bivector_candidate?(pp)
      true
  """
  def bivector_candidate?(x) do
    grade?(x, 2) and not zero?(wedge(x, e_inf()))
  end

  @doc """
  Extracts the Euclidean parameters of an OPNS circle or line.

  Returns either

    * `{:circle, {:real | :imag, {x, y}, radius}}`
    * `{:line, {a, b, c}}`

  where the line satisfies `ax + by + c = 0`.

  ## Examples

      iex> circle_parameters(circle(point(1, 2), 3))
      {:circle, {:real, {1.0, 2.0}, 3.0}}

      iex> circle_parameters(circle(point(1, 2), -3.0))
      {:circle, {:imag, {1.0, 2.0}, 3.0}}
  """
  def circle_parameters(c) do
    v = gp(c, inverse!(pseudoscalar()))

    e1 = coefficient(v, :e1)
    e2 = coefficient(v, :e2)

    ep = coefficient(v, :ep)
    em = coefficient(v, :em)

    w = em - ep

    if not above_epsilon?(norm(wedge(c, e_inf()))) do
      {:line, line_parameters(c)}
    else
      x = e1 / w
      y = e2 / w

      k = (em + ep) / (2 * w)

      b =
        x * x +
          y * y -
          2 * k

      r =
        abs(b) ** 0.5

      type = if(b < 0.0, do: :imag, else: :real)
      {:circle, {type, {clean_zero(x), clean_zero(y)}, r}}
    end
  end

  @doc """
  Splits a bivector into point representatives.

  Returns

  * `{p1, p2}` for a non-tangent pair,
  * `{:tangent, p}` for a tangent pair,
  * `:error` when it cannot split the bivector.

  For disjoint circles, the pair can split into two pseudo-points whose
  Euclidean coordinates do not lie on either circle. Do not treat the tuple
  alone as proof of real intersection points; check incidence with the
  original objects when real endpoints are needed.

  ## Examples

      iex> l = line(point(-2, 0), point(2, 0))
      iex> c = circle(point(0, 0), 1)
      iex> {p1, p2} = split(meet(c, l))
      iex> Enum.sort([point_coordinates(p1), point_coordinates(p2)])
      [{-1.0, 0.0}, {1.0, 0.0}]

      iex> c1 = circle(point(-0.5, 0), 1)
      iex> c2 = circle(point(0.5, 0), 1)
      iex> {p1, p2} = split(meet(c1, c2))
      iex> [{x1, y1}, {x2, y2}] = Enum.sort([point_coordinates(p1), point_coordinates(p2)])
      iex> abs(x1) < 1.0e-10 and abs(x2) < 1.0e-10
      true
      iex> (y1 < 0) != (y2 < 0)
      true
      iex> abs(abs(y1) - 0.75 ** 0.5) < 1.0e-10
      true
      iex> abs(abs(y2) - 0.75 ** 0.5) < 1.0e-10
      true

      iex> split(meet(circle(point(0, 0), 1), circle(point(0, 0), 1)))
      :error

      iex> c1 = circle(point(0, 0), 1)
      iex> c2 = circle(point(5, 0), 1)
      iex> {p1, p2} = split(meet(c1, c2))
      iex> Enum.all?([p1, p2], fn p -> contains?(c1, p) or contains?(c2, p) end)
      false

      iex> l = line(point(-1, 1), point(1, 1))
      iex> c = circle(point(0, 0), 1)
      iex> {:tangent, p} = split(meet(c, l))
      iex> point_coordinates(p)
      {0.0, 1.0}

      iex> pp = join(point(0.0, 0.0), point(1, 0))
      iex> {a, b} = split(pp)
      iex> point_coordinates(a)
      {1.0, 0.0}
      iex> point_coordinates(b)
      {0.0, 0.0}
  """

  def split(b) do
    scalar_product(b, b)
    |> case do
      bb when bb == 0.0 ->
        wedge(b, e_inf())
        |> inverse()
        |> case do
          :error ->
            :error

          {:ok, inv} ->
            pos = gp(b, inv)
            w = scalar_product(pos, sub(e_inf(), one()))

            {:tangent, scale(pos, 1.0 / w)}
        end

      bb ->
        b = if(bb < 0, do: gp(b, pseudoscalar()), else: b)

        b_bar = b |> scale(1 / scalar_product(b, b) ** 0.5)
        p = one() |> add(b_bar)
        p_tilde = one() |> sub(b_bar)

        v = inner(b, new(em: 1))
        p1 = gp(p, v)
        p2 = gp(p_tilde, v)

        {p1, p2}
    end
  end

  @doc """
  Lifts an affine point representative back into the conformal point embedding.

  ## Examples

      iex> lift_point(point(2, 3))
      ...> |> point_coordinates()
      {2.0, 3.0}

      iex> lift_point(point(2, 3))
      add(add(e_o(), add(new(e1: 2), new(e2: 3))), scale(6.5, e_inf()))

      iex> point_coordinates(lift_point(point(4, 5)))
      {4.0, 5.0}

      iex> point?(lift_point(point(1, 2)))
      true
  """
  def lift_point(p) do
    x = scalar_product(p, new(e1: 1))
    y = scalar_product(p, new(e2: 1))

    point(x, y)
  end

  @doc """
  Classifies a geometric object and extracts its Euclidean parameters.

  Returns one of

    * `{:point, {x, y}}`
    * `{:line, {a, b, c}}`
    * `{:circle, {:real | :imag, {x, y}, radius}}`
    * `{:point_pair, p1, p2}` for a non-tangent pair
    * `{:point_pair, p}` for a tangent pair
    * `{:unknown, multivector}`

  Point-pair coordinates from disjoint circles can be pseudo-points rather
  than real intersections; verify incidence before treating them as endpoints.
  The generated `point?/1` excludes `point(0, 0)`, so the conformal origin
  is classified as unknown even though `point_coordinates/1` accepts it.

  ## Examples

      iex> classify(point(2, 3))
      {:point, {2.0, 3.0}}

      iex> classify(point(-5, 4))
      {:point, {-5.0, 4.0}}

      iex> {point?(point(0, 0)), point_coordinates(point(0, 0))}
      {false, {0.0, 0.0}}

      iex> {:line, {a, b, c}} = classify(line(point(0, 0), point(0, 1)))
      iex> abs(a) == 1.0 and b == 0.0 and c == 0.0
      true

      iex> {:line, {a, b, c}} = classify(line(point(0, 0), point(1, 0)))
      iex> a == 0.0 and abs(b) == 1.0 and c == 0.0
      true

      iex> classify(circle(point(0, 0), 2))
      {:circle, {:real, {0.0, 0.0}, 2.0}}

      iex> classify(circle(point(3, -2), 5))
      {:circle, {:real, {3.0, -2.0}, 5.0}}

      iex> pp =
      ...>   meet(
      ...>     circle(point(0, 0), 2),
      ...>     line(point(-3, 0), point(3, 0))
      ...>   )
      iex> {:point_pair, p1, p2} = classify(pp)
      iex> Enum.sort([p1, p2])
      [{-2.0, 0.0}, {2.0, 0.0}]

      iex> pp =
      ...>   meet(
      ...>     circle(point(0, 0), 1),
      ...>     line(point(-2, 0), point(2, 0))
      ...>   )
      iex> match?({:point_pair, _, _}, classify(pp))
      true

      iex> pp =
      ...>   meet(
      ...>     circle(point(1, 2), 1),
      ...>     circle(point(3, 2), 1)
      ...>   )
      iex> classify(pp)
      {:point_pair, {2.0, 2.0}}

      iex> pp =
      ...>   meet(
      ...>     circle(point(1, -1), 1),
      ...>     circle(point(1, -3), 1)
      ...>   )
      iex> classify(pp)
      {:point_pair, {1.0, -2.0}}

      iex> classify(meet(circle(point(0, 0), 1), circle(point(0, 0), 1)))
      {:unknown, ~G[0.0]}

      iex> classify(new(e1: 1))
      {:unknown, new(e1: 1)}

      iex> {:point_pair, _, _} =  classify(join(point(0, 0), point(1, 0)))
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
        end

      bivector_candidate?(x) ->
        split(x)
        |> case do
          {:tangent, p} ->
            {
              :point_pair,
              point_coordinates(p)
            }

          {p1, p2} ->
            {
              :point_pair,
              point_coordinates(p1),
              point_coordinates(p2)
            }
        end

      true ->
        {:unknown, x}
    end
  end

  @doc """
  Returns the Euclidean coefficients of an OPNS line.

  The returned tuple `{a, b, c}` satisfies

      `ax + by + c = 0`

  ## Examples

      iex> {a, b, c} = line_parameters(line(point(0, 0), point(0, 1)))
      iex> {abs(a), b, c}
      {1.0, 0.0, 0.0}

      iex> line_parameters(line(point(0, 0), point(1, 2)))
      {-2.0, 1.0, 0.0}

      iex> line_parameters(line(point(0, 0), point(1, 0)))
      {0.0, 1.0, 0.0}
  """
  def line_parameters(l) do
    l = hodge_dual(l)

    {
      coefficient(l, :e1),
      coefficient(l, :e2),
      0.5 * scalar_product(l, e_inf())
    }
  end
end
