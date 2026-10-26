defmodule Galixir.GeometricAlgebra do
  @moduledoc """
  Provides a macro for generating concrete geometric algebra modules.

  A generated algebra module contains operations for creating and manipulating
  multivectors, including geometric products, outer products, inverses, duals,
  norms, grade extraction, and basis blade helpers.

  The algebra is defined by a diagonal metric and a set of basis identifiers.

  ## Usage

      defmodule PGA3 do
        use Galixir.GeometricAlgebra,
          metric: {1, 1, 1, 0},
          bases: {"1", "2", "3", "0"}
      end

  ## Metric

  The `:metric` option defines the metric of the algebra. Each element
  describes the square of the corresponding basis vector:

    * `1`  - Euclidean basis vector (`eᵢ² = 1`)
    * `-1` - anti-Euclidean basis vector (`eᵢ² = -1`)
    * `0`  - null basis vector (`eᵢ² = 0`)

  For example, `{1, 1, 1, 0}` defines a 3D projective geometric algebra (PGA)
  with three Euclidean basis vectors and one null basis vector.

  ## Bases

  The optional `:bases` option defines the identifiers used for basis vectors.
  The number of bases must match the dimension of the metric.

  Basis identifiers must be unique single-character strings. By default, the
    identifiers are `"1"` through `"9"` for metrics of up to nine dimensions.
    Larger metrics require explicit identifiers. For example:

    bases: {"1", "2", "3", "4"}


  For algebras with a special basis convention, such as projective geometric
  algebra (PGA), the identifiers can be customized:

    bases: {"1", "2", "3", "0"}

  This allows the null basis vector to be represented as `e0`, producing blade
  names such as:

    e1
    e2
    e3
    e0
    e123
    e230

  The identifiers are only used for naming basis blades; they do not affect the
  metric. The metric is defined exclusively by the `:metric` option.

  ## Generated API

  The generated module provides:

    * multivector construction with `new/1`
    * coefficient access
    * geometric product (`gp/2`)
    * outer product (`wedge/2`)
    * addition, subtraction, and scaling
    * reverse and dual operations
    * grade extraction
    * scalar and inner products
    * norms and normalization
    * inverses
    * grade-homogeneity and scalar predicates
    * `pseudoscalar/0` and named basis-blade coefficients through `new/1`

  It also provides higher-level helpers:

    * `commutator/2` for the Lie algebra commutator
    * `rotor_between_frames/2` for normalizing `1 + T * S⁻¹` from frame blades
  """

  alias Galixir.Table

  @doc """
  Generates a geometric algebra implementation from a metric.

  This macro is intended to be used inside a module definition.

  ## Options

    * `:metric` - required tuple describing the metric.
      Each element corresponds to the square of one basis vector.

    * `:bases` - optional tuple of unique single-character strings naming the
      basis vectors. The number of bases must match the metric dimension.
      Defaults to `"1"` through the dimension for metrics of up to nine dimensions;
      larger metrics require explicit identifiers.

    * `:epsilon` - optional non-negative float for selected near-zero checks;
      defaults to `1.0e-10`. Other operations may use exact comparisons or
      their own threshold.

  ## Examples

      defmodule GA3 do
        use Galixir.GeometricAlgebra,
          metric: {1, 1, 1},
          bases: {"1", "2", "3"}
      end

      defmodule PGA3 do
        use Galixir.GeometricAlgebra,
          metric: {1, 1, 1, 0},
          bases: {"1", "2", "3", "0"},
          epsilon: 1.0e-8
      end

  """
  defmacro __using__(opts) do
    module = __CALLER__.module

    metric =
      opts
      |> Keyword.fetch!(:metric)
      |> Code.eval_quoted([], __CALLER__)
      |> case do
        {metric, _} -> metric
      end

    unless is_tuple(metric) and tuple_size(metric) > 0 do
      raise ArgumentError, ":metric must be a nonempty tuple, given: #{inspect(metric)}"
    end

    for m <- Tuple.to_list(metric), m not in [-1, 0, 1] do
      raise ArgumentError,
            "Each metric element must be -1, 0 or 1, given metric #{inspect(metric)}"
    end

    bases =
      opts
      |> Keyword.get(:bases)
      |> then(&if(&1, do: Code.eval_quoted(&1, [], __CALLER__)))
      |> case do
        nil -> default_bases(tuple_size(metric))
        {b, _} -> b
      end

    epsilon =
      opts
      |> Keyword.get(:epsilon, 1.0e-10)

    if not is_float(epsilon) or epsilon < 0.0 do
      raise ArgumentError,
            ":epsilon option is required to be a non-negative floating point number, given: #{inspect(epsilon)}"
    end

    unless is_tuple(bases) do
      raise ArgumentError, ":bases must be a tuple, given: #{inspect(bases)}"
    end

    for b <- Tuple.to_list(bases), not is_binary(b) or String.length(b) != 1 do
      raise ArgumentError,
            "Each basis name must be a string of length 1, given basis names #{inspect(bases)}"
    end

    if tuple_size(bases) != tuple_size(metric) do
      raise ArgumentError,
            "number of bases (given #{inspect(bases)}) must be the same as the size of the metric (given #{inspect(metric)})"
    end

    if bases |> Tuple.to_list() |> Enum.uniq() |> length() != tuple_size(bases) do
      raise ArgumentError, "Basis names must be unique, given: #{inspect(bases)}"
    end

    table = Table.build(metric)

    dimension = tuple_size(metric)

    blade_indices = Galixir.Generator.blade_indices(bases)
    blade_aliases = Galixir.Generator.blade_aliases(bases)

    meta = %Galixir.Meta{
      module: module,
      dimensions: dimension,
      metric: metric,
      bases: bases,
      table: table,
      blade_indices: blade_indices,
      blade_aliases: blade_aliases,
      epsilon: epsilon
    }

    ast =
      quote do
        defstruct [:data]

        unquote_splicing(
          for g <- Galixir.GeneratorRegistry.generators(),
              part <- g.generate_implementation(meta) do
            part
          end
        )

        @doc unquote("""
             Computes the commutator product of two multivectors.

             The commutator is defined as half the difference between the geometric
             products in opposite orders:

                 [a, b] = (a * b - b * a) / 2

             This measures the non-commutativity of the geometric product.

             ## Examples

             #{if(dimension > 1,
             do: """
                 iex> commutator(new(e#{elem(bases, 0)}: 1), new(e#{elem(bases, 1)}: 1))
                 new(e#{elem(bases, 0)}#{elem(bases, 1)}: 1)

                 iex> commutator(new(e#{elem(bases, 1)}: 1), new(e#{elem(bases, 0)}: 1))
                 new(e#{elem(bases, 0)}#{elem(bases, 1)}: -1)
             """,
             else: "")}
                 iex> commutator(new(e#{elem(bases, 0)}: 1), new(e#{elem(bases, 0)}: 1))
                 new()

                 iex> commutator(new(e#{elem(bases, 0)}: 1), new(scalar: 2))
                 new()
             """)
        def commutator(a, b) do
          scale(
            0.5,
            sub(gp(a, b), gp(b, a))
          )
        end

        @doc unquote("""
             Computes the outer product of a list of multivectors.

             The inputs are combined from left to right using the wedge product.

             For vector inputs, the result is a blade representing their oriented
             span (or zero if they are dependent). For arbitrary multivectors,
             the result need not be a single blade.

             ## Examples

                 iex> wedge_all([])
                 new(scalar: 1)

                 iex> wedge_all([new(e#{elem(bases, 0)}: 1)])
                 new(e#{elem(bases, 0)}: 1)

                 iex> wedge_all([new(e#{elem(bases, 0)}: 1), new(e#{elem(bases, 0)}: 1)])
                 new()

             #{if(dimension > 2,
             do: """
                 iex> wedge_all([new(e#{elem(bases, 0)}: 1), new(e#{elem(bases, 1)}: 1)])
                 new(e#{elem(bases, 0)}#{elem(bases, 1)}: 1)

                 iex> wedge_all([new(e#{elem(bases, 1)}: 1), new(e#{elem(bases, 0)}: 1)])
                 new(e#{elem(bases, 0)}#{elem(bases, 1)}: -1)
             """,
             else: "")}#{if(dimension > 3,
             do: """
                 iex> wedge_all([new(e#{elem(bases, 0)}: 1), new(e#{elem(bases, 1)}: 1), new(e#{elem(bases, 2)}: 1)])
                 new(e#{elem(bases, 0)}#{elem(bases, 1)}#{elem(bases, 2)}: 1)
             """,
             else: "")}
             """)

        @doc group: :product
        def wedge_all(vectors) do
          Enum.reduce(vectors, one(), fn v, acc ->
            wedge(acc, v)
          end)
        end

        @doc unquote("""
             Computes the rotor that maps one frame to another.

             The function constructs blades from the source and target frames and computes
             the transformation rotor:

             `R = normalize(1 + T * S⁻¹)`

             where `S` is the source frame blade and `T` is the target frame blade.

             This expression is only useful when `S` is invertible and the sum
             has non-zero norm; otherwise `inverse!/1` or `normalize!/1` raises.
             No check is made that the inputs form frames or that the result
             maps each source vector to its corresponding target vector.
             """)
        def rotor_between_frames(source, target) do
          source_blade = wedge_all(source)
          target_blade = wedge_all(target)

          gp(target_blade, inverse!(source_blade))
          |> add(new(scalar: 1))
          |> normalize!()
        end
      end

    ast
  end

  defp default_bases(dimension) when dimension <= 9 do
    List.to_tuple(Enum.map(1..dimension, &Integer.to_string/1))
  end

  defp default_bases(_dimension) do
    raise ArgumentError,
          ":bases must be supplied explicitly for metrics with more than 9 dimensions"
  end
end
