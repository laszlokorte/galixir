defmodule Galixir.Algebras.Models.PGA do
  defmacro __using__(opts) do
    {dimensions, _} = Code.eval_quoted(Keyword.fetch!(opts, :dimensions), [], __CALLER__)
    names = if is_tuple(dimensions), do: Tuple.to_list(dimensions), else: []
    dim = length(names)

    unless is_tuple(dimensions) and dim > 0 and
             Enum.all?(names, &(is_binary(&1) and &1 != "")) do
      raise ArgumentError, "PGA dimensions must be a nonempty tuple of nonempty coordinate names"
    end

    indices = Enum.to_list(1..dim)

    bases = List.to_tuple(Enum.map(indices, &Integer.to_string/1) ++ ["0"])
    metric = List.to_tuple(List.duplicate(1, dim) ++ [0])
    coordinates = Enum.map(names, &Macro.var(String.to_atom(&1), nil))
    scale = Macro.var(:homogeneous_scale, nil)
    point_basis = String.to_atom("e#{Enum.join(indices)}")

    # The coefficient of each ideal blade is obtained by translating the
    # origin: e1...en * e0i. Cancel the repeated ei, then count the swaps
    # needed to put the remaining indices in the chosen blade order.
    ideal_terms =
      for i <- indices do
        before = Enum.take(indices, i - 1)
        after_i = Enum.drop(indices, i)
        blade_indices = [0 | Enum.reverse(before) ++ Enum.reverse(after_i)]
        product_indices = before ++ after_i ++ [0]
        swaps_to_cancel = length(after_i) + 1

        swaps_to_blade =
          for {left, position} <- Enum.with_index(product_indices),
              right <- Enum.drop(product_indices, position + 1),
              reduce: 0 do
            swaps ->
              swaps +
                if(
                  Enum.find_index(blade_indices, &(&1 == left)) >
                    Enum.find_index(blade_indices, &(&1 == right)),
                  do: 1,
                  else: 0
                )
          end

        {String.to_atom("e#{Enum.join(blade_indices)}"),
         if(rem(swaps_to_cancel + swaps_to_blade, 2) == 0, do: 1, else: -1)}
      end

    {ideal_bases, orientation} = Enum.unzip(ideal_terms)
    vector_bases = Enum.map(indices, &String.to_atom("e#{&1}"))
    translation_bases = Enum.map(indices, &String.to_atom("e0#{&1}"))
    values = indices
    ones = List.duplicate(0, dim)

    point_fields =
      [{point_basis, scale}] ++
        Enum.map(Enum.zip([ideal_bases, coordinates, orientation]), fn {blade, value, sign} ->
          {blade, quote(do: unquote(sign) * unquote(value) * unquote(scale))}
        end)

    vector_fields = Enum.zip(vector_bases, coordinates)

    ideal_fields =
      Enum.zip([ideal_bases, coordinates, orientation])
      |> Enum.map(fn {blade, value, sign} ->
        {blade, quote(do: unquote(sign) * unquote(value))}
      end)

    translation_fields =
      [{:scalar, 1}] ++
        Enum.zip_with(translation_bases, coordinates, fn blade, value ->
          {blade, quote(do: -unquote(value) / 2)}
        end)

    point_args = coordinates ++ [quote(do: unquote(scale) \\ 1)]

    coordinate_values =
      Enum.zip_with(ideal_bases, orientation, fn blade, sign ->
        quote(do: clean_zero(unquote(sign) * coefficient(p, unquote(blade)) / w))
      end)

    direction_values =
      Enum.zip_with(ideal_bases, orientation, fn blade, sign ->
        quote(do: unquote(sign) * coefficient(d, unquote(blade)))
      end)

    vector_values = for blade <- vector_bases, do: quote(do: coefficient(v, unquote(blade)))
    coords_a = for _ <- names, do: Macro.unique_var(:a, __CALLER__.module)
    coords_b = for _ <- names, do: Macro.unique_var(:b, __CALLER__.module)

    distances =
      Enum.zip_with(coords_a, coords_b, fn a, b ->
        quote(do: (unquote(a) - unquote(b)) * (unquote(a) - unquote(b)))
      end)

    module_name = inspect(__CALLER__.module)
    point_call = "point(#{Enum.join(values, ", ")})"
    ideal_call = "ideal_point(#{Enum.join(values, ", ")})"
    vector_call = "vector(#{Enum.join(values, ", ")})"
    tuple = inspect(List.to_tuple(Enum.map(values, &(&1 * 1.0))))
    origin_call = "point(#{Enum.join(ones, ", ")})"

    point_formula =
      "e#{Enum.join(indices)}" <>
        Enum.map_join(Enum.zip([names, ideal_bases, orientation]), fn {name, blade, sign} ->
          "#{if sign < 0, do: " - ", else: " + "}#{name}*#{blade}"
        end)

    objects =
      "hyperplanes are grade-1 vectors; " <>
        "the nonzero intersection of k independent hyperplanes has grade k; " <>
        "points are grade-#{dim} blades"

    docs = """
    #{dim}-dimensional Euclidean geometry in the dual projective geometric algebra.

    The algebra has signature `Cl(#{dim},0,1)`, metric `#{inspect(metric)}` and
    basis `#{Enum.map_join(Tuple.to_list(bases), ", ", &"e#{&1}")}`. The null
    basis vector `e0` is the ideal hyperplane (the hyperplane at infinity).
    In this dual representation, #{objects}. Euclidean vectors are distinct
    from ideal points. The exterior product of dependent hyperplanes vanishes.

    The join is `hodge_undual(wedge(hodge_dual(a), hodge_dual(b)))`;
    the meet is `wedge(a, b)`.
    For a point with Cartesian coordinates `#{Enum.join(names, ", ")}` and
    homogeneous coefficient `w` on `#{point_basis}`, the orientation is
    `P = w*(#{point_formula})`. Finite coordinates require a homogeneous
    coefficient above the implementation's epsilon threshold.

    ## Example

        iex> p = #{module_name}.#{point_call}
        iex> #{module_name}.point_coordinates(p)
        #{tuple}
    """

    quote do
      @moduledoc unquote(docs)
      use Galixir.GeometricAlgebra,
        metric: unquote(Macro.escape(metric)),
        bases: unquote(Macro.escape(bases))

      @doc """
      Returns the Euclidean origin.

          iex> point_coordinates(origin())
          #{unquote(inspect(List.to_tuple(Enum.map(ones, &(&1 * 1.0)))))}
      """
      def origin, do: point(unquote_splicing(ones))

      @doc """
      Creates a point with the given homogeneous scale (default `1`). A zero
      scale, where accepted, produces the zero multivector. A nonzero scale
      gives a nonzero homogeneous component, but finite-point checks and
      coordinate extraction use epsilon thresholds; very small scales may
      raise during canonicalization or coordinate extraction.

          iex> point_coordinates(#{unquote(point_call)})
          #{unquote(tuple)}
          iex> point_coordinates(#{unquote(String.replace(point_call, ")", ", 2)"))})
          #{unquote(tuple)}
      """
      def point(unquote_splicing(point_args)), do: new(unquote(point_fields))
      defoverridable point: unquote(dim + 1)

      @doc """
      Creates an ideal point (a direction at infinity).

          iex> ideal_point?(#{unquote(ideal_call)})
          true
      """
      def ideal_point(unquote_splicing(coordinates)), do: new(unquote(ideal_fields))

      @doc """
      Tests whether a grade-#{unquote(dim)} point has a homogeneous component
      above the epsilon threshold after canonicalization. A zero multivector
      cannot be canonicalized; sufficiently small points may also fail
      canonicalization.

          iex> finite_point?(#{unquote(point_call)})
          true
          iex> finite_point?(#{unquote(ideal_call)})
          false
      """
      def finite_point?(p),
        do:
          grade?(p, unquote(dim)) and
            above_epsilon?(coefficient(canonicalize!(p), unquote(point_basis)))

      @doc """
      Tests whether a grade-#{unquote(dim)} point has a homogeneous component
      at or below the epsilon threshold after canonicalization. A zero
      multivector is not an ideal point and cannot be canonicalized.

          iex> ideal_point?(#{unquote(ideal_call)})
          true
          iex> ideal_point?(#{unquote(point_call)})
          false
      """
      def ideal_point?(p),
        do:
          grade?(p, unquote(dim)) and
            not above_epsilon?(coefficient(canonicalize!(p), unquote(point_basis)))

      @doc """
      Returns Cartesian coordinates of a point whose raw homogeneous
      coefficient exceeds the epsilon threshold. Raises for ideal points and
      points with too small a homogeneous coefficient.

          iex> point_coordinates(#{unquote(point_call)})
          #{unquote(tuple)}
          iex> point_coordinates(#{unquote(ideal_call)})
          ** (ArgumentError) cannot extract Cartesian coordinates from a non-finite point
      """
      def point_coordinates(p) do
        w = coefficient(p, unquote(point_basis))

        if not above_epsilon?(w),
          do: raise(ArgumentError, "cannot extract Cartesian coordinates from a non-finite point")

        {unquote_splicing(coordinate_values)}
      end

      @doc """
      Creates a Euclidean direction vector, not an ideal point.

          iex> #{unquote(vector_call)}
          new(#{unquote(Enum.zip_with(vector_bases, values, fn blade, value -> "#{blade}: #{value}" end) |> Enum.join(", "))})
      """
      def vector(unquote_splicing(coordinates)), do: new(unquote(vector_fields))

      @doc """
      Computes the join via dualization and the outer product.

          iex> incident?(#{unquote(point_call)}, #{unquote(point_call)})
          true
      """
      def join(a, b), do: hodge_undual(wedge(hodge_dual(a), hodge_dual(b)))

      @doc "Computes the meet as the outer product. Parallel objects can yield ideal elements."
      def meet(a, b), do: wedge(a, b)

      @doc "Tests incidence by checking whether the join vanishes."
      def incident?(a, b), do: zero?(join(a, b))

      @doc """
      Tests whether two homogeneous objects represent the same entity.

          iex> coincident?(#{unquote(point_call)}, #{unquote(String.replace(point_call, ")", ", 2)"))})
          true
      """
      def coincident?(a, b),
        do: grade(a) == grade(b) and zero?(sub(canonicalize!(a), canonicalize!(b)))

      @doc """
      Creates a translation motor from coordinates or a Euclidean vector.

          iex> point_coordinates(transform(origin(), translator(#{unquote(Enum.join(values, ", "))})))
          #{unquote(tuple)}
          iex> point_coordinates(transform(origin(), translator(#{unquote(vector_call)})))
          #{unquote(tuple)}
      """
      def translator(%__MODULE__{} = v), do: translator(unquote_splicing(vector_values))

      def translator(unquote_splicing(coordinates)), do: new(unquote(translation_fields))

      @doc """
      Applies a motor sandwich transformation to a geometric object.

          iex> point_coordinates(transform(origin(), translator(#{unquote(Enum.join(values, ", "))})))
          #{unquote(tuple)}
      """
      def transform(object, motor), do: gp(gp(motor, object), inverse!(motor))
      defoverridable transform: 2

      @doc """
      Returns the vector from `a` to `b` when both points have the same unit
      homogeneous scale. This subtracts raw point coefficients without
      normalizing by homogeneous weight, so other scales change the result;
      for arbitrary finite points use `point_coordinates/1` first.

          iex> direction_between_points(#{unquote(origin_call)}, #{unquote(point_call)})
          new(#{unquote(Enum.zip_with(vector_bases, values, fn blade, value -> "#{blade}: #{value}" end) |> Enum.join(", "))})
          iex> direction_between_points(#{unquote(origin_call)}, #{unquote(String.replace(point_call, ")", ", 2)"))})
          new(#{unquote(Enum.zip_with(vector_bases, values, fn blade, value -> "#{blade}: #{2 * value}" end) |> Enum.join(", "))})
      """
      def direction_between_points(a, b) do
        d = sub(b, a)
        vector(unquote_splicing(direction_values))
      end

      @doc """
      Computes the Euclidean distance between finite points whose raw
      homogeneous coefficients exceed the epsilon threshold.

          iex> distance(#{unquote(origin_call)}, #{unquote(point_call)})
          #{unquote(Enum.reduce(values, 0, fn x, acc -> acc + x * x end) ** 0.5)}
      """
      def distance(a, b) do
        {unquote_splicing(coords_a)} = point_coordinates(a)
        {unquote_splicing(coords_b)} = point_coordinates(b)

        unquote(Enum.reduce(distances, fn x, acc -> quote(do: unquote(acc) + unquote(x)) end)) **
          0.5
      end

      @doc "Negates a multivector."
      def negate(x), do: scale(-1.0, x)

      @doc "Computes the metric scalar product of two multivectors."
      def scalar_product(a, b), do: a |> inner(b) |> scalar_part()

      defp clean_zero(x) when x == 0.0, do: 0.0
      defp clean_zero(x), do: x
    end
  end
end
