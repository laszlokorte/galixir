defmodule Galixir.Algebras.Models.CGA do
  defmacro __using__(opts) do
    additional_docs = Keyword.get(opts, :docs, "")

    {dimensions, _} =
      opts
      |> Keyword.fetch!(:dimensions)
      |> Code.eval_quoted([], __CALLER__)

    unless is_tuple(dimensions) and tuple_size(dimensions) > 0 and
             Enum.all?(Tuple.to_list(dimensions), &(is_binary(&1) and &1 != "")) do
      raise ArgumentError, "CGA dimensions must be a nonempty tuple of coordinate names"
    end

    dimnames = Tuple.to_list(dimensions)
    dim = length(dimnames)

    metric = List.to_tuple(List.duplicate(1, dim + 1) ++ [-1])
    bases = List.to_tuple(Enum.map(1..dim, &Integer.to_string/1) ++ ["p", "m"])
    args = Enum.map(dimnames, &Macro.var(String.to_atom(&1), nil))
    fields = Enum.zip(Enum.map(1..dim, &String.to_atom("e#{&1}")), args)

    norm_squared =
      Enum.reduce(args, quote(do: 0), fn arg, acc ->
        quote(do: unquote(acc) + unquote(arg) * unquote(arg))
      end)

    coordinate_fields =
      for index <- 1..dim do
        quote do
          clean_zero(scalar_product(p, new(unquote([{String.to_atom("e#{index}"), 1}]))) / w)
        end
      end

    names = Enum.join(dimnames, ", ")
    sample = Enum.to_list(1..dim)
    displacement = Enum.take(Stream.cycle([3, -1, 2]), dim)
    shifted = Enum.zip_with(sample, displacement, &+/2)
    origin = List.duplicate(0, dim)
    first_axis = [1 | List.duplicate(0, dim - 1)]
    third_point = Enum.map(sample, &(&1 + 1))
    sample_tuple = sample |> Enum.map(&(&1 * 1.0)) |> List.to_tuple() |> inspect()
    shifted_tuple = shifted |> Enum.map(&(&1 * 1.0)) |> List.to_tuple() |> inspect()
    module_name = inspect(__CALLER__.module)
    point_call = "point(#{Enum.join(sample, ", ")})"
    vector_call = "vector(#{Enum.join(sample, ", ")})"
    translation_call = "translator(#{Enum.join(displacement, ", ")})"

    other_basis = "new(e1: 1, ep: 1)"

    module_doc = """
    #{dim}-dimensional Conformal Geometric Algebra (CGA).

    The Euclidean coordinates (#{names}) use metric `#{inspect(metric)}` and
    basis `{#{Enum.map_join(Tuple.to_list(bases), ", ", &"e#{&1}")}}`.
    The positive and negative conformal axes `ep` and `em` define the
    null vectors `e_inf = em + ep` and `e_o = (em - ep) / 2`.
    Points embed as `e_o + x + (x · x)/2 * e_inf`.

    Operations on multivectors are provided by `Galixir.GeometricAlgebra`.
    The pseudoscalar converts between OPNS and IPNS representations.

    ## Examples

        iex> p = #{module_name}.#{point_call}
        iex> #{module_name}.point_coordinates(p)
        #{sample_tuple}

    #{additional_docs}
    """

    vector_doc = """
    Creates a Euclidean vector from (#{names}). It is not a conformal point.

    ## Examples

        iex> point?(#{vector_call})
        false
        iex> point?(#{point_call})
        true
    """

    point_doc = """
    Embeds a Euclidean point (#{names}) as `e_o + x + (x · x)/2 * e_inf`.

    ## Examples

        iex> point_coordinates(#{point_call})
        #{sample_tuple}
    """

    coordinates_doc = """
    Extracts the #{dim} Euclidean coordinates of a finite conformal point,
    independently of its homogeneous scale, provided the weight
    `-p · e_inf` has magnitude greater than `epsilon()`. A nonzero weight
    at or below that threshold raises the same "point at infinity" error.

    ## Examples

        iex> #{point_call} |> scale(7) |> point_coordinates()
        #{sample_tuple}
        iex> #{point_call} |> scale(1.0e-12) |> point_coordinates()
        ** (ArgumentError) cannot extract coordinates from point at infinity
    """

    translator_doc = """
    Creates a translator motor from the Euclidean displacement (#{names}).

    ## Examples

        iex> #{point_call} |> transform(#{translation_call}) |> point_coordinates()
        #{shifted_tuple}
    """

    join_doc = """
    Computes the outer product join of CGA objects. Objects represented in
    IPNS form should be converted to OPNS form before joining.

    ## Examples

        iex> grades(join(point(#{Enum.join(origin, ", ")}), point(#{Enum.join(first_axis, ", ")})))
        [2]
        iex> grades(join(point(#{Enum.join(origin, ", ")}), point(#{Enum.join(first_axis, ", ")}), point(#{Enum.join(third_point, ", ")})))
        [3]
    """

    normalize_doc = """
    Scales a conformal point so that `p · e_o = -1` when its
    `p · e_o` value is nonzero. Raises `ArgumentError` otherwise (including
    at the conformal origin).

    ## Examples

        iex> normalized = #{point_call} |> scale(5) |> normalize_point()
        iex> scalar_product(normalized, e_o())
        -1.0

        iex> coords = normalize_point(scale(#{point_call}, 100)) |> point_coordinates()
        iex> Enum.zip(Tuple.to_list(coords), #{inspect(sample)}) |> Enum.all?(fn {actual, expected} -> abs(actual - expected) < 1.0e-10 end)
        true
    """

    quote do
      @moduledoc unquote(module_doc)
      use Galixir.GeometricAlgebra,
        metric: unquote(Macro.escape(metric)),
        bases: unquote(Macro.escape(bases))

      @doc """
      Returns the null conformal infinity vector `em + ep`.

      ## Examples

          iex> scalar_product(e_inf(), e_inf())
          0.0
      """
      def e_inf, do: new(em: 1, ep: 1)

      @doc """
      Returns the null conformal origin vector `(em - ep) / 2`.

      ## Examples

          iex> scalar_product(e_o(), e_inf())
          -1.0
      """
      def e_o, do: scale(0.5, sub(new(em: 1), new(ep: 1)))

      @doc unquote(vector_doc)
      def vector(unquote_splicing(args)), do: new(unquote(fields))

      @doc unquote(point_doc)
      def point(unquote_splicing(args)) do
        add(
          add(e_o(), vector(unquote_splicing(args))),
          scale(0.5 * unquote(norm_squared), e_inf())
        )
      end

      @doc unquote(coordinates_doc)
      def point_coordinates(p) do
        w = -scalar_product(p, e_inf())

        if not above_epsilon?(w) do
          raise ArgumentError, "cannot extract coordinates from point at infinity"
        end

        unquote({:{}, [], coordinate_fields})
      end

      @doc unquote(join_doc)
      def join(a, b), do: wedge(a, b)
      def join(a, b, c), do: wedge(wedge(a, b), c)

      @doc unquote(translator_doc)
      def translator(unquote_splicing(args)) do
        t = add(one(), scale(-0.5, gp(vector(unquote_splicing(args)), e_inf())))
        normalize!(t)
      end

      @doc """
      Applies a motor to an object using the sandwich product `M * X * reverse(M)`.

      ## Examples

          iex> #{unquote(point_call)} |> transform(#{unquote(translation_call)}) |> point_coordinates()
          #{unquote(shifted_tuple)}
      """
      def transform(object, motor), do: gp(gp(motor, object), reverse(motor))

      @doc """
      Computes the scalar part of the geometric product under the CGA metric.

      ## Examples

          iex> scalar_product(new(e1: 1), new(e1: 1))
          1.0
          iex> scalar_product(#{unquote(point_call)}, new(e1: 1))
          1.0
      """
      def scalar_product(a, b), do: scalar_part(gp(a, b))

      @doc unquote(normalize_doc)
      def normalize_point(p) do
        w = scalar_product(p, e_o())

        if not above_epsilon?(w) do
          raise ArgumentError, "cannot normalize point with zero weight, given #{inspect(p)}"
        end

        scale(p, -1.0 / w)
      end

      @doc """
      Returns whether a multivector is a grade-1 null conformal point whose
      `p · e_o` magnitude exceeds `epsilon()`.

      This generated predicate does not recognize the conformal origin:
      `e_o · e_o = 0`. A concrete algebra may override it to include the origin.

      ## Examples

          iex> point?(#{unquote(point_call)})
          true
          iex> point?(#{unquote(other_basis)})
          false
      """
      def point?(p) do
        grade?(p, 1) and null?(p) and above_epsilon?(scalar_product(p, e_o()))
      end

      @doc """
      Removes coefficients whose magnitude is below `eps`.

      ## Examples

          iex> new(e1: 1.0, ep: 1.0e-12) |> cleanup() |> coefficient(:ep)
          0.0
      """
      def cleanup(m, eps \\ epsilon()) do
        %__MODULE__{data: data} = m

        data =
          data
          |> Tuple.to_list()
          |> Enum.map(fn x -> if abs(x) < eps, do: 0.0, else: x end)
          |> List.to_tuple()

        %__MODULE__{data: data}
      end

      defp null?(p) do
        n2 = abs(scalar_product(p, p))

        scale =
          p.data
          |> Tuple.to_list()
          |> Enum.map(&abs/1)
          |> Enum.sum()

        not above_epsilon?(n2, @epsilon * max(scale * scale, 1.0))
      end

      # Avoid returning IEEE-754 negative zero in coordinate tuples.
      defp clean_zero(x) when x == 0.0, do: 0.0
      defp clean_zero(x), do: x
    end
  end
end
