defmodule Galixir.Algebras.CGA3 do
  use Galixir.Algebras.Models.CGA, dimensions: {"x", "y", "z"}

  defoverridable point?: 1

  @doc """
  Tests whether a multivector is a finite conformal point, including the origin.

      iex> point?(point(0, 0, 0))
      true
      iex> point?(vector(1, 2, 3))
      false
  """
  def point?(p), do: finite_point?(p)

  @doc """
  Constructs an OPNS sphere from its center and signed radius. Negative radii
  encode negative squared radius. `sphere_parameters/1` classifies squared
  radii within `1.0e-10` of zero as tangent, so a sufficiently small negative
  radius can be reported as tangent rather than imaginary.

  ## Examples

      iex> sphere_parameters(sphere(1, 2, 3, 4))
      {:sphere, {:real, {1.0, 2.0, 3.0}, 4.0}}
      iex> sphere_parameters(sphere(point(0, 0, 0), -2))
      {:sphere, {:imag, {0.0, 0.0, 0.0}, 2.0}}
      iex> sphere_parameters(sphere(0, 0, 0, -1.0e-6))
      {:sphere, {:tangent, {0.0, 0.0, 0.0}, 0.0}}
  """
  def sphere(center, radius) do
    sub(center, scale(0.5 * radius * abs(radius), e_inf()))
    |> gp(inverse!(pseudoscalar()))
  end

  def sphere(x, y, z, radius), do: sphere(point(x, y, z), radius)

  @doc """
  Constructs an OPNS sphere through four conformal points. Four coplanar,
  noncocircular points produce a plane; four cocircular points produce a
  degenerate zero blade instead.

      iex> s = sphere_from_points(point(1, 0, 0), point(0, 1, 0), point(0, 0, 1), point(-1, 0, 0))
      iex> sphere_parameters(s)
      {:sphere, {:real, {0.0, 0.0, 0.0}, 1.0}}
      iex> plane?(sphere_from_points(point(0, 0, 0), point(1, 0, 0), point(0, 1, 0), point(2, 2, 0)))
      true
      iex> zero?(sphere_from_points(point(0, 0, 0), point(1, 0, 0), point(0, 1, 0), point(1, 1, 0)))
      true
  """
  def sphere_from_points(a, b, c, d), do: wedge(join(a, b, c), d)

  @doc """
  Constructs an OPNS plane `normal · x = distance`. The normal is normalized;
  a zero normal raises `ArgumentError`.

  ## Examples

      iex> plane_parameters(plane({0, 0, 2}, 3))
      {{0.0, 0.0, 1.0}, 3.0}
      iex> contains?(plane({0, 0, 1}, 2), point(4, -1, 2))
      true
      iex> plane_parameters(plane({0, 0, 0}, 2))
      ** (ArgumentError) plane normal must not be zero
  """
  def plane({nx, ny, nz}, distance) do
    length = :math.sqrt(nx * nx + ny * ny + nz * nz)
    if length <= epsilon(), do: raise(ArgumentError, "plane normal must not be zero")

    add(vector(nx / length, ny / length, nz / length), scale(distance, e_inf()))
    |> gp(inverse!(pseudoscalar()))
  end

  @doc """
  Constructs an OPNS plane through three conformal points. Collinear inputs
  produce a degenerate zero blade.

      iex> plane_from_points(point(0, 0, 1), point(1, 0, 1), point(0, 1, 1)) |> plane?()
      true
  """
  def plane_from_points(a, b, c), do: wedge(join(a, b, c), e_inf())

  @doc """
  Constructs an OPNS circle in the plane through `center`, with the given
  normal. A negative radius encodes a negative squared radius; values close
  enough to zero are classified as tangent by `circle_parameters/1`.

  ## Examples

      iex> {:circle, {:real, center, radius, normal}} = circle_parameters(circle({1, 2, 3}, 2, {0, 0, 1}))
      iex> {x, y, z} = center
      iex> Enum.all?([{x, 1}, {y, 2}, {z, 3}, {radius, 2}], fn {actual, expected} -> abs(actual - expected) < 1.0e-10 end) and normal == {0.0, 0.0, 1.0}
      true
      iex> circle_parameters(circle({1, 2, 3}, 0, {1, 2, 3})) |> elem(0)
      :circle
  """
  def circle(%__MODULE__{} = center, radius, normal),
    do: circle(point_coordinates(center), radius, normal)

  def circle({x, y, z}, radius, {nx, ny, nz} = normal) do
    length = :math.sqrt(nx * nx + ny * ny + nz * nz)
    if length <= epsilon(), do: raise(ArgumentError, "circle normal must not be zero")
    meet(sphere(x, y, z, radius), plane(normal, (nx * x + ny * y + nz * z) / length))
  end

  @doc """
  Creates the OPNS circle (or, for collinear points, line) through three points.
  For point-derived circles, the normal reported by `circle_parameters/1`
  points opposite to the normal of `plane_from_points(a, b, c)` in this
  basis convention. Reversing point order reverses both normals.

      iex> c = circle_from_points(point(1, 0, 0), point(0, 1, 0), point(-1, 0, 0))
      iex> {:circle, {:real, center, radius, _}} = classify(c)
      iex> {center, radius}
      {{0.0, 0.0, 0.0}, 1.0}
      iex> line?(circle_from_points(point(0, 0, 0), point(1, 0, 0), point(2, 0, 0)))
      true
      iex> a = point(1, 0, 0); b = point(0, 1, 0); c = point(-1, 0, 0)
      iex> {:circle, {:real, _, _, normal}} = circle_from_points(a, b, c) |> circle_parameters()
      iex> {normal, plane_parameters(plane_from_points(a, b, c)) |> elem(0)}
      {{0.0, 0.0, -1.0}, {0.0, 0.0, 1.0}}
  """
  def circle_from_points(a, b, c), do: join(a, b, c)
  def line_or_circle_from_points(a, b, c), do: circle_from_points(a, b, c)

  @doc """
  Constructs an OPNS line through two finite points.

  ## Examples

      iex> line?(line(point(0, 0, 0), point(1, 0, 0)))
      true
      iex> contains?(line(point(0, 0, 0), point(1, 0, 0)), point(3, 0, 0))
      true
  """
  def line(a, b), do: wedge(join(a, b), e_inf())

  @doc "Creates an OPNS point pair through two conformal points."
  def point_pair(a, b), do: join(a, b)

  @doc """
  Computes the OPNS intersection via the pseudoscalar dual. Intersections
  with insufficient codimension (such as two lines) may have zero algebraic
  meet even when they intersect; use incidence for those cases.

  ## Examples

      iex> pp = meet(sphere(0, 0, 0, 1), line(point(-2, 0, 0), point(2, 0, 0)))
      iex> {a, b} = split(pp)
      iex> Enum.sort([point_coordinates(a), point_coordinates(b)])
      [{-1.0, 0.0, 0.0}, {1.0, 0.0, 0.0}]
      iex> {:circle, {:real, center, radius, _}} = classify(meet(sphere(0, 0, 0, 2), plane({0, 0, 1}, 1)))
      iex> {x, y, z} = center
      iex> abs(x) < 1.0e-10 and abs(y) < 1.0e-10 and abs(z - 1) < 1.0e-10 and abs(radius - :math.sqrt(3)) < 1.0e-10
      true
      iex> classify(meet(plane({1, 0, 0}, 1), plane({0, 1, 0}, 2))) |> elem(0)
      :line
  """
  def meet(a, b) do
    i_inv = inverse!(pseudoscalar())
    wedge(gp(a, i_inv), gp(b, i_inv)) |> gp(pseudoscalar())
  end

  @doc """
  Tests whether a finite conformal point lies on an OPNS object.

      iex> contains?(sphere(0, 0, 0, 2), point(0, 0, 2))
      true
      iex> contains?(sphere(0, 0, 0, 2), point(0, 0, 3))
      false
  """
  def contains?(object, p) do
    finite_point?(p) and not zero?(object) and
      near_zero_product?(wedge(object, p), object, p)
  end

  @doc "Alias of `contains?/2` for point/object incidence."
  def incident?(object, p), do: contains?(object, p)

  @doc "Returns true for a nondegenerate OPNS sphere (not a plane)."
  def sphere?(s),
    do:
      grade?(s, 4) and not zero?(s) and not plane?(s) and
        finite_weight?(gp(s, inverse!(pseudoscalar())))

  @doc "Returns true for a nondegenerate OPNS plane."
  def plane?(p) do
    if grade?(p, 4) and not zero?(p) do
      v = gp(p, inverse!(pseudoscalar()))

      near_zero_number?(-scalar_product(v, e_inf()), v) and
        :math.sqrt(euclidean_norm2(v)) > epsilon() * max_coefficient(v)
    else
      false
    end
  end

  @doc "Returns true for an OPNS line (including circles through collinear points)."
  def line?(l) do
    grade?(l, 3) and not zero?(l) and near_zero?(wedge(l, e_inf()), l) and
      Enum.any?(
        [:e1pm, :e2pm, :e3pm],
        &(abs(coefficient(l, &1)) > epsilon() * max_coefficient(l))
      ) and
      simple_line?(l)
  end

  @doc "Returns true for a nondegenerate OPNS circle."
  def circle?(c) do
    grade?(c, 3) and not zero?(c) and not line?(c) and
      match?({:circle, _}, circle_parameters(c))
  end

  @doc "Returns true for an OPNS circle or line."
  def circle_or_line?(c), do: circle?(c) or line?(c)

  @doc "Returns true for a finite real, imaginary or tangent OPNS point pair."
  def point_pair?(b), do: point_pair_parameters(b) != :error

  @doc "Returns true for an imaginary point pair (no real endpoints)."
  def imaginary_point_pair?(b), do: match?({:imag, _, _, _}, point_pair_parameters(b))

  @doc "Returns true for a grade-2 candidate; use `split/1` to check for real points."
  def bivector_candidate?(b),
    do: grade?(b, 2) and not zero?(b) and not near_zero?(wedge(b, e_inf()), b)

  @doc """
  Extracts a sphere's center and real, imaginary or tangent radius. Squared
  radii from `-1.0e-10` through `1.0e-10` are classified as tangent with
  radius `0.0`, including spheres constructed with small negative radii.
  Returns `:error` for planes or invalid spheres.
  """
  def sphere_parameters(s) do
    if grade?(s, 4) and not zero?(s) do
      v = gp(s, inverse!(pseudoscalar()))
      w = -scalar_product(v, e_inf())

      if near_zero_number?(w, v) do
        :error
      else
        {x, y, z} = {coefficient(v, :e1) / w, coefficient(v, :e2) / w, coefficient(v, :e3) / w}
        k = scalar_product(v, e_o()) / -w
        r2 = x * x + y * y + z * z - 2 * k
        type = radius_type(r2)
        radius = if type == :tangent, do: 0.0, else: :math.sqrt(abs(r2))
        {:sphere, {type, coordinates(x, y, z), radius}}
      end
    else
      :error
    end
  end

  @doc """
  Extracts `{{nx, ny, nz}, distance}` from an OPNS plane, or `:error`.
  The normal has unit length and the equation is `n · x = distance`.
  """
  def plane_parameters(p) do
    if plane?(p) do
      v = gp(p, pseudoscalar())
      {nx, ny, nz} = {coefficient(v, :e1), coefficient(v, :e2), coefficient(v, :e3)}
      length = :math.sqrt(nx * nx + ny * ny + nz * nz)
      distance = -scalar_product(v, e_o()) / length
      {coordinates(nx / length, ny / length, nz / length), clean(distance)}
    else
      :error
    end
  end

  @doc """
  Extracts circle center, radius and unit normal, or `:error`. Negative
  squared radii below `-1.0e-10` are imaginary; squared radii within
  `1.0e-10` of zero are classified as tangent with radius `0.0`.
  The normal follows the oriented circle blade: multiplying the blade by a
  negative number reverses it. For circles joined from points it is opposite
  to `plane_from_points/3` for the same ordered inputs.

      iex> c = circle({1, 2, 3}, 2, {1, 2, 3}) |> scale(1.0e5)
      iex> {:circle, {:real, {x, y, z}, r, {nx, ny, nz}}} = circle_parameters(c)
      iex> Enum.all?([{x, 1}, {y, 2}, {z, 3}, {r, 2}, {nx, 1 / :math.sqrt(14)}, {ny, 2 / :math.sqrt(14)}, {nz, 3 / :math.sqrt(14)}], fn {actual, expected} -> abs(actual - expected) < 1.0e-10 end)
      true
      iex> circle?(c) and not circle?(new(e123: 1, e12p: 1, e3pm: 1) |> scale(1.0e5))
      true
  """
  def circle_parameters(c) do
    if grade?(c, 3) and not zero?(c) and not near_zero?(wedge(c, e_inf()), c) do
      b = gp(scale(c, 1.0 / max_coefficient(c)), inverse!(pseudoscalar()))
      p = inner(b, e_inf())
      pn2 = euclidean_norm2(p)

      if pn2 <= epsilon() ** 2 * max_coefficient(b) ** 2 or
           not near_zero_product?(wedge(b, b), b, b) or
           not near_zero_number?(-scalar_product(p, e_inf()), p) do
        :error
      else
        # For C* = S ∧ P, contraction with infinity yields a multiple of P.
        # Removing the plane factor recovers the centered IPNS sphere.
        s = gp(b, scale(1.0 / pn2, p))

        case sphere_parameters(gp(cleanup(s), pseudoscalar()) |> cleanup()) do
          {:sphere, {type, center, radius}} ->
            {normal, _} = plane_parameters(gp(scale(-1, p), pseudoscalar()))
            {:circle, {type, center, radius, normal}}

          :error ->
            :error
        end
      end
    else
      :error
    end
  end

  @doc """
  Extracts a line's closest point to the origin and unit direction as
  `{point, direction}`, or `:error`. Direction depends on blade orientation.

      iex> line_parameters(line(point(1, 2, 3), point(2, 2, 3)))
      {{0.0, 2.0, 3.0}, {1.0, 0.0, 0.0}}
  """
  def line_parameters(l) do
    if line?(l) do
      # L = (a ∧ b) ∧ infinity. Its e_ipm terms give the direction,
      # and the remaining Euclidean/infinity terms encode its moment.
      {dx, dy, dz} = {coefficient(l, :e1pm), coefficient(l, :e2pm), coefficient(l, :e3pm)}
      d2 = dx * dx + dy * dy + dz * dz

      if d2 <= epsilon() ** 2 * max_coefficient(l) ** 2 do
        :error
      else
        # Translating the line to its closest point gives the perpendicular
        # component of its moment (e_ij times infinity).
        {mx, my, mz} = {
          coefficient(l, :e23p),
          -coefficient(l, :e13p),
          coefficient(l, :e12p)
        }

        px = (dy * mz - dz * my) / d2
        py = (dz * mx - dx * mz) / d2
        pz = (dx * my - dy * mx) / d2
        len = :math.sqrt(d2)
        {coordinates(px, py, pz), coordinates(dx / len, dy / len, dz / len)}
      end
    else
      :error
    end
  end

  @doc """
  Splits a real point pair into conformal points. Returns `{:tangent, p}`
  for coincident intersection points and `:error` for imaginary or invalid
  pairs (which have no real conformal endpoints).

      iex> split(point_pair(point(0, 0, 0), point(2, 0, 0))) |> then(fn {a, b} -> Enum.sort([point_coordinates(a), point_coordinates(b)]) end)
      [{0.0, 0.0, 0.0}, {2.0, 0.0, 0.0}]
      iex> {:tangent, p} = meet(sphere(0, 0, 0, 1), line(point(-2, 1, 0), point(2, 1, 0))) |> split()
      iex> point_coordinates(p)
      {0.0, 1.0, 0.0}
      iex> split(meet(sphere(0, 0, 0, 1), line(point(-2, 2, 0), point(2, 2, 0))))
      :error
      iex> pair = point_pair(point(1, 2, 3), point(2, 3, 5)) |> scale(1.0e-6)
      iex> {a, b} = split(pair)
      iex> coords = Enum.sort([point_coordinates(a), point_coordinates(b)])
      iex> Enum.zip(coords, [{1, 2, 3}, {2, 3, 5}]) |> Enum.all?(fn {actual, expected} -> Enum.zip(Tuple.to_list(actual), Tuple.to_list(expected)) |> Enum.all?(fn {x, y} -> abs(x - y) < 1.0e-10 end) end)
      true
  """
  def split(b) do
    if bivector_candidate?(b) and near_zero_product?(wedge(b, b), b, b) do
      b = scale(b, 1.0 / max_coefficient(b))
      bb = scalar_product(b, b)

      cond do
        near_zero_product_number?(bb, b, b) ->
          with {:ok, inv} <- inverse(wedge(b, e_inf())),
               p <- gp(b, inv),
               w <- -scalar_product(p, e_inf()),
               true <- above_epsilon?(w) and finite_point?(p) do
            {:tangent, scale(p, 1.0 / w) |> cleanup()}
          else
            _ -> :error
          end

        bb > 0 ->
          v = inner(b, new(em: 1))
          unit = scale(b, 1.0 / :math.sqrt(bb))
          p1 = gp(add(one(), unit), v) |> cleanup()
          p2 = gp(sub(one(), unit), v) |> cleanup()

          if finite_point?(p1) and finite_point?(p2) do
            {scale(p1, 1.0 / -scalar_product(p1, e_inf())) |> cleanup(),
             scale(p2, 1.0 / -scalar_product(p2, e_inf())) |> cleanup()}
          else
            :error
          end

        true ->
          :error
      end
    else
      :error
    end
  end

  @doc """
  Re-embeds a multivector's Euclidean vector component as a conformal point.
  This discards any existing homogeneous scale or infinity component.

      iex> lift_point(vector(2, 3, 4)) |> point_coordinates()
      {2.0, 3.0, 4.0}
  """
  def lift_point(p),
    do: point(coefficient(p, :e1), coefficient(p, :e2), coefficient(p, :e3))

  @doc """
  Extracts point-pair parameters. Real pairs return their endpoints, tangent
  pairs return one point, and imaginary pairs return their center, positive
  imaginary half-separation and unit axis. Returns `:error` for invalid pairs.

  ## Examples

      iex> point_pair_parameters(point_pair(point(0, 0, 0), point(2, 0, 0)))
      {:real, {2.0, 0.0, 0.0}, {0.0, 0.0, 0.0}}
      iex> pp = meet(sphere(0, 0, 0, 1), line(point(-2, 2, 0), point(2, 2, 0)))
      iex> point_pair_parameters(pp)
      {:imag, {0.0, 2.0, 0.0}, 1.7320508075688772, {1.0, 0.0, 0.0}}
      iex> imaginary_point_pair?(pp) and point_pair?(pp)
      true
      iex> pair = point_pair(point(1, 2, 3), point(2, 3, 5))
      iex> match?({:real, _, _}, point_pair_parameters(pair)) and match?({:real, _, _}, point_pair_parameters(scale(pair, 1.0e-6)))
      true
      iex> invalid = new(e12: 1, e3p: 1)
      iex> point_pair?(scale(invalid, 1.0e-6)) or point_pair?(scale(invalid, 1.0e5))
      false
  """
  def point_pair_parameters(b) do
    if bivector_candidate?(b) and near_zero_product?(wedge(b, b), b, b) do
      b = scale(b, 1.0 / max_coefficient(b))

      case split(b) do
        {:tangent, p} ->
          {:tangent, point_coordinates(p)}

        {a, c} ->
          {:real, point_coordinates(a), point_coordinates(c)}

        :error ->
          bb = scalar_product(b, b)
          v = inner(b, e_inf())
          v2 = euclidean_norm2(v)

          if bb < -epsilon() * max_coefficient(b) ** 2 and
               v2 > epsilon() ** 2 * max_coefficient(b) ** 2 do
            center = gp(b, scale(1.0 / v2, v))

            if finite_weight?(center) do
              direction =
                coordinates(
                  coefficient(v, :e1) / :math.sqrt(v2),
                  coefficient(v, :e2) / :math.sqrt(v2),
                  coefficient(v, :e3) / :math.sqrt(v2)
                )

              {:imag, point_coordinates(center), :math.sqrt(-bb / v2), direction}
            else
              :error
            end
          else
            :error
          end
      end
    else
      :error
    end
  end

  @doc """
  Classifies OPNS objects. Real point pairs return two endpoints, tangent
  pairs one point and imaginary pairs center, radius and axis.

      iex> classify(point(1, 2, 3))
      {:point, {1.0, 2.0, 3.0}}
      iex> classify(sphere(0, 0, 0, 0))
      {:sphere, {:tangent, {0.0, 0.0, 0.0}, 0.0}}
      iex> classify(point(0, 0, 0))
      {:point, {0.0, 0.0, 0.0}}
      iex> pair = point_pair(point(1, 2, 3), point(2, 3, 5))
      iex> match?({:point_pair, _, _}, classify(pair)) and match?({:point_pair, _, _}, classify(scale(pair, 1.0e-6)))
      true
      iex> classify(meet(sphere(0, 0, 0, 1), sphere(0, 0, 0, 1))) |> elem(0)
      :unknown
  """
  def classify(x) do
    cond do
      finite_point?(x) ->
        {:point, point_coordinates(x)}

      plane?(x) ->
        {:plane, plane_parameters(x)}

      sphere?(x) ->
        sphere_parameters(x)

      line?(x) ->
        {:line, line_parameters(x)}

      circle?(x) ->
        circle_parameters(x)

      bivector_candidate?(x) ->
        case point_pair_parameters(x) do
          {:tangent, p} -> {:point_pair, p}
          {:real, a, b} -> {:point_pair, a, b}
          {:imag, center, radius, axis} -> {:point_pair, {:imag, center, radius, axis}}
          :error -> {:unknown, x}
        end

      true ->
        {:unknown, x}
    end
  end

  defp simple_line?(l) do
    dual = gp(l, inverse!(pseudoscalar()))
    near_zero_product?(wedge(dual, dual), dual, dual)
  end

  defp finite_point?(p) do
    grade?(p, 1) and not zero?(p) and finite_weight?(p) and
      near_zero_product_number?(scalar_product(p, p), p, p)
  end

  defp finite_weight?(v), do: not near_zero_number?(-scalar_product(v, e_inf()), v)

  defp euclidean_norm2(v),
    do: Enum.reduce([:e1, :e2, :e3], 0.0, fn axis, sum -> sum + coefficient(v, axis) ** 2 end)

  defp near_zero?(a, reference),
    do: max_coefficient(a) <= epsilon() * max_coefficient(reference)

  defp near_zero_number?(n, reference),
    do: abs(n) <= epsilon() * max_coefficient(reference)

  defp near_zero_product?(result, a, b),
    do: max_coefficient(result) <= epsilon() * max_coefficient(a) * max_coefficient(b)

  defp near_zero_product_number?(n, a, b),
    do: abs(n) <= epsilon() * max_coefficient(a) * max_coefficient(b)

  defp max_coefficient(v), do: v.data |> Tuple.to_list() |> Enum.map(&abs/1) |> Enum.max()
  defp radius_type(r2) when r2 < -1.0e-10, do: :imag
  defp radius_type(r2) when r2 > 1.0e-10, do: :real
  defp radius_type(_), do: :tangent
  defp coordinates(x, y, z), do: {clean(x), clean(y), clean(z)}
  defp clean(x) when abs(x) < 1.0e-10, do: 0.0
  defp clean(x), do: x * 1.0
end
