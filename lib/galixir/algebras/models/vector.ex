defmodule Galixir.Algebras.Models.Vector do
  @moduledoc """
  Generates a Euclidean geometric algebra from a tuple of coordinate names.

  `use Galixir.Algebras.Models.Vector, dimensions: {"x", "y"}` defines
  Cartesian vector and bivector helpers in the using module. The generated
  `rotor/2` represents an axis rotation only in three dimensions.
  """

  @example_values [3.0, 4.0, 5.0, -3.0, -5.0, -4.0, 1.0, 3.0, 5.0, 1.0]

  defp example_values(count) do
    Enum.take(@example_values, count)
  end

  defmacro __using__(opts) do
    additional_docs = Keyword.get(opts, :docs, "")

    dimnames =
      Keyword.fetch(opts, :dimensions)
      |> case do
        {:ok, d} when is_tuple(d) and tuple_size(d) >= 1 ->
          d
          |> Code.eval_quoted([], __CALLER__)
          |> case do
            {metric, _} -> metric
          end
          |> Tuple.to_list()

        e ->
          raise ArgumentError, "dimension must be a tuple of dimension names, #{inspect(e)} given"
      end

    #   module = __CALLER__.module
    dim = length(dimnames)
    metric = List.to_tuple(for _ <- 1..dim, do: 1)
    bases_list = for d <- 1..dim, do: "#{d}"
    bases = List.to_tuple(bases_list)

    bidimnames =
      for {a, i} <- Enum.with_index(dimnames),
          {b, j} <- Enum.with_index(dimnames),
          i < j do
        "#{a}#{b}"
      end

    bibases =
      for i <- 1..dim, j <- 1..dim, i < j do
        "#{i}#{j}"
      end

    args =
      Enum.map(dimnames, fn name ->
        Macro.var(String.to_atom(name), nil)
      end)

    biargs =
      Enum.map(bidimnames, fn name ->
        Macro.var(String.to_atom(name), nil)
      end)

    values = example_values(length(dimnames))
    bivalues = example_values(length(biargs))

    fields =
      dimnames
      |> Enum.zip_with(bases_list, fn name, ba ->
        {String.to_atom("e#{ba}"), Macro.var(String.to_atom(name), nil)}
      end)

    bifields =
      bidimnames
      |> Enum.zip_with(bibases, fn name, biba ->
        {String.to_atom("e#{biba}"), Macro.var(String.to_atom(name), nil)}
      end)

    quote do
      @moduledoc """
      #{unquote(dim)}-dimensional Euclidean geometric algebra, `Cl(#{unquote(dim)}, 0)`.

      This is a classic, non-projective vector algebra: grade-1 multivectors are
      ordinary Cartesian vectors. Its metric is `#{unquote(inspect(metric))}` and its basis is
      #{unquote(for(d <- 1..dim, do: "`e#{d}`") |> Enum.join(", "))}.

      `v = #{unquote(for({d, i} <- Enum.with_index(dimnames, 1), do: "#{d} * e#{i}") |> Enum.join(" + "))}`

      Bivectors represent oriented planes and generate rotations. The
      pseudoscalar `e#{unquote(for(d <- 1..dim, do: d) |> Enum.join(""))}`
      maps grade-`k` blades to complementary grade-`#{unquote(dim)} - k` blades
      under Hodge duality. In three dimensions, this gives the familiar
      vector cross product.

      #{unquote(additional_docs)}
      """

      use Galixir.GeometricAlgebra,
        metric: unquote(Macro.escape(metric)),
        bases: unquote(Macro.escape(bases))

      @doc """
      Creates the Cartesian vector `#{unquote(for({d, i} <- Enum.with_index(dimnames, 1), do: "#{d} * e#{i}") |> Enum.join(" + "))}`.

      ## Examples

          iex> vector(#{unquote(values |> Enum.join(", "))})
          new(#{unquote(bases_list |> Enum.zip_with(values, fn b, v -> "e#{b}: #{v}" end) |> Enum.join(", "))})
      """
      def vector(unquote_splicing(args)) do
        new(unquote(fields))
      end

      @doc """
      Extracts the Cartesian coordinates of a vector.

      ## Examples

          iex> coordinates(vector(#{unquote(values |> Enum.join(", "))}))
          {#{unquote(values |> Enum.join(", "))}}
      """
      def coordinates(v) do
        {unquote_splicing(
           Enum.with_index(dimnames, 1)
           |> Enum.map(fn {_name, index} ->
             quote do
               coefficient(v, unquote(:"e#{index}"))
             end
           end)
         )}
      end

      @doc """
      Checks whether a multivector is a vector (a pure grade-1 multivector).

      ## Examples

          iex> vector?(vector(#{unquote(values |> Enum.join(", "))}))
          true

          iex> vector?(pseudoscalar())
          false
      """
      def vector?(v), do: grade?(v, 1)

      @doc """
      Computes the Euclidean scalar product of two vectors.

      ## Examples

          iex> scalar_product(vector(#{unquote(values |> Enum.join(", "))}), vector(#{unquote(values |> Enum.join(", "))}))
          #{unquote(Enum.zip_with(values, values, &(&1 * &2)) |> Enum.sum())}
      """
      def scalar_product(a, b), do: scalar_part(gp(a, b))

      @doc """
      Computes the squared Euclidean length of a vector.

      ## Examples

          iex> squared_length(vector(#{unquote(values |> Enum.join(", "))}))
          #{unquote(Enum.zip_with(values, values, &(&1 * &2)) |> Enum.sum())}
      """
      def squared_length(v), do: scalar_product(v, v)

      @doc """
      Computes the Euclidean length of a vector.

      ## Examples

          iex> len(vector(#{unquote(values |> Enum.join(", "))}))
          #{unquote(Enum.zip_with(values, values, &(&1 * &2)) |> Enum.sum() |> then(&(&1 ** 0.5)))}
      """
      def len(v), do: squared_length(v) ** 0.5

      @doc """
      Normalizes a non-zero vector to unit length.

      Raises `ArgumentError` for the zero vector.

      ## Examples

          iex> normal(vector(#{unquote(1..dim |> Enum.map_join(", ", fn
        1 -> 2
        _ -> 0
      end))})) |> coordinates()
          {#{unquote(1..dim |> Enum.map_join(", ", fn
        1 -> 1.0
        _ -> 0.0
      end))}}
      """
      def normal(v), do: normalize!(v)

      @doc """
      Returns the unsigned angle between two non-zero vectors, in radians.

      ## Examples

          iex> angle(vector(#{unquote(1..dim |> Enum.map_join(", ", fn
        1 -> 1
        _ -> 0
      end))}), vector(#{unquote(1..dim |> Enum.map_join(", ", fn
        2 -> 1
        _ -> 0
      end))}))
          :math.pi() / 2
      """
      def angle(a, b) do
        cosine = scalar_product(a, b) / (len(a) * len(b))
        :math.acos(min(1.0, max(-1.0, cosine)))
      end

      @doc """
      Projects vector `v` onto a non-zero vector `onto`.

      ## Examples

          iex> project(vector(#{unquote(values |> Enum.join(", "))}), vector(#{unquote(1..dim |> Enum.map_join(", ", fn
        1 -> 1
        _ -> 0
      end))})) |> coordinates()
          {#{unquote(values |> Enum.with_index() |> Enum.map_join(", ", fn
        {v, 0} -> v
        _ -> 0.0
      end))}}
      """
      def project(v, onto) do
        scale(scalar_product(v, onto) / squared_length(onto), onto)
      end

      @doc """
      Returns the component of `v` perpendicular to `onto`.

      ## Examples

          iex> reject(vector(#{unquote(values |> Enum.join(", "))}), vector(#{unquote(1..dim |> Enum.map_join(", ", fn
        1 -> 1
        _ -> 0
      end))})) |> coordinates()
          {#{unquote(values |> Enum.with_index() |> Enum.map_join(", ", fn
        {_, 0} -> 0.0
        {v, _} -> v
      end))}}
      """
      def reject(v, onto), do: sub(v, project(v, onto))

      @doc """
      Computes the Euclidean distance between two vectors interpreted as points.

      ## Examples

          iex> distance(vector(#{unquote(values |> Enum.join(", "))}), vector(#{unquote(values |> Enum.reverse() |> Enum.join(", "))}))
          #{unquote(Enum.zip_with(values, Enum.reverse(values), &((&1 - &2) ** 2.0)) |> Enum.sum() |> then(&(&1 ** 0.5)))}
      """
      def distance(a, b), do: len(sub(a, b))

      @doc """
      Creates an oriented bivector from its coordinate-plane components.

          B = #{unquote(Enum.zip_with(bidimnames, bibases, fn name, basis -> "#{name}*e#{basis}" end) |> Enum.join(" + "))}

      ## Examples

          iex> bivector(#{unquote(bivalues |> Enum.join(", "))})
          new(#{unquote(Enum.zip_with(bivalues, bibases, fn v, b -> "e#{b}: #{v}" end) |> Enum.join(", "))})
      """
      def bivector(unquote_splicing(biargs)), do: new(unquote(bifields))

      @doc """
      Extracts a bivector's coordinate-plane components in basis order.

      ## Examples

          iex> bivector_coordinates(bivector(#{unquote(bivalues |> Enum.join(", "))}))
          {#{unquote(bivalues |> Enum.join(", "))}}
      """
      def bivector_coordinates(b),
        do: {
          unquote_splicing(
            for b <- bibases do
              quote do
                coefficient(b, :"e#{unquote(b)}")
              end
            end
          )
        }

      unquote_splicing(
        for {{biba, dim}, bix} <- bibases |> Enum.zip(bidimnames) |> Enum.with_index() do
          bibases =
            0..(length(bibases) - 1)
            |> Enum.map(fn
              ^bix -> 1
              _ -> 0
            end)

          function_name = :"bivector_#{dim}"

          quote do
            @doc """
            Returns the #{unquote(dim)} plane bivector `e#{unquote(biba)}`.

            ## Examples

                iex> bivector_#{unquote(dim)}()
                new(#{unquote("e#{biba}")}: 1)
            """
            def unquote(function_name)(), do: bivector(unquote_splicing(bibases))
          end
        end
      )

      @doc """
      Constructs `cos(angle/2) - sin(angle/2) * hodge_dual(normal(axis))`.

      In three dimensions, this is a rotor about non-zero `axis`; positive
      angles follow the right-hand rule. In other dimensions, this expression
      does not generally produce a rotation rotor.

      ## Examples

          iex> vector(#{unquote(values |> Enum.join(", "))})
          ...> |> rotate(rotor(vector(#{unquote(1..dim |> Enum.map_join(", ", fn
        1 -> 1
        _ -> 0
      end))}), :math.pi()))
          ...> |> rotate(rotor(vector(#{unquote(1..dim |> Enum.map_join(", ", fn
        1 -> 1
        _ -> 0
      end))}), :math.pi()))
          ...> |> coordinates() |> Tuple.to_list() |> Enum.map(&Float.round(&1, 12))
          [#{unquote(values |> Enum.join(", "))}]
      """
      def rotor(axis, angle) do
        plane = axis |> normal() |> hodge_dual()
        add(new(scalar: :math.cos(angle / 2)), scale(-:math.sin(angle / 2), plane))
      end

      @doc """
      Applies the sandwich product `r*v*reverse(r)` to a multivector.

      When `r` is a rotation rotor, this rotates `v`. In particular, `rotor/2`
      constructs such a rotor in three dimensions, but not generally in two
      or four dimensions.

      ## Examples

          iex> vector(#{unquote(values |> Enum.join(", "))})
          ...> |> rotate(rotor(vector(#{unquote(1..dim |> Enum.map_join(", ", fn
        1 -> 1
        _ -> 0
      end))}), :math.pi()))
          ...> |> rotate(rotor(vector(#{unquote(1..dim |> Enum.map_join(", ", fn
        1 -> 1
        _ -> 0
      end))}), :math.pi()))
          ...> |> coordinates() |> Tuple.to_list() |> Enum.map(&Float.round(&1, 12))
          [#{unquote(values |> Enum.join(", "))}]
      """
      def rotate(v, r), do: gp(gp(r, v), reverse(r))

      @doc """
      Reflects vector `v` in the hyperplane whose normal is non-zero vector `n`.

      ## Examples

          iex> reflect(vector(#{unquote(values |> Enum.join(", "))}), vector(#{unquote(1..dim |> Enum.map_join(", ", fn
        1 -> 1
        _ -> 0
      end))})) |> coordinates()
          {#{unquote(values |> Enum.with_index() |> Enum.map_join(", ", fn
        {v, 0} -> -v
        {v, _} -> v
      end))}}
      """
      def reflect(v, n), do: negate(gp(gp(n, v), inverse!(n)))

      @doc """
      Negates every component of a multivector.

      ## Examples

          iex> negate(vector(#{unquote(values |> Enum.join(", "))}))
          vector(#{unquote(values |> Enum.map_join(", ", &(-&1)))})
      """
      def negate(x), do: scale(-1, x)
    end
  end
end
