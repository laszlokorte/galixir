defmodule Galixir.GeometricAlgebra do
  @moduledoc """
  Provides a macro for generating concrete geometric algebra modules.

  A generated algebra module contains operations for creating and manipulating
  multivectors, including geometric products, outer products, inverses, duals,
  norms, grade extraction, and basis blade helpers.

  The algebra is defined by a metric signature and a set of basis identifiers.

  ## Usage

      defmodule PGA3 do
        use Galixir.GeometricAlgebra,
          signature: {1, 1, 1, 0},
          bases: {1, 2, 3, 0}
      end

  ## Signature

  The `:signature` option defines the metric of the algebra. Each element
  describes the square of the corresponding basis vector:

    * `1`  - Euclidean basis vector (`eᵢ² = 1`)
    * `-1` - anti-Euclidean basis vector (`eᵢ² = -1`)
    * `0`  - null basis vector (`eᵢ² = 0`)

  For example, `{1, 1, 1, 0}` defines a 3D projective geometric algebra (PGA)
  with three Euclidean basis vectors and one null basis vector.

  ## Bases

  The optional `:bases` option defines the identifiers used for basis vectors.
  The number of bases must match the dimension of the signature.

  By default, basis identifiers are generated as consecutive integers starting
  from `1`. For example, a four-dimensional algebra without an explicit `:bases`
  option uses:

    bases: {1, 2, 3, 4}

  For algebras with a special basis convention, such as projective geometric
  algebra (PGA), the identifiers can be customized:

    bases: {1, 2, 3, 0}

  This allows the null basis vector to be represented as `e0`, producing basis
  blades such as:

    e1
    e2
    e3
    e0
    e123
    e230

  The identifiers are only used for naming basis blades; they do not affect the
  metric. The metric is defined exclusively by the `:signature` option.

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
    * blade and scalar predicates
    * basis blade constructors

  It also provides higher-level helpers:

    * `commutator/2` for the Lie algebra commutator
    * `rotor_between_frames/2` for constructing rotors mapping one frame to another
  """

  alias Galixir.Generator.Inverse
  alias Galixir.Generator.Predicates
  alias Galixir.Table

  @doc """
  Generates a geometric algebra implementation from a metric signature.

  This macro is intended to be used inside a module definition.

  ## Options

    * `:signature` - required tuple describing the metric signature.
      Each element corresponds to the square of one basis vector.

    * `:bases` - optional tuple containing names for the basis vectors.
      The number of bases must match the signature dimension.

  ## Examples

      defmodule GA3 do
        use Galixir.GeometricAlgebra,
          signature: {1, 1, 1}
      end

      defmodule PGA3 do
        use Galixir.GeometricAlgebra,
          signature: {1, 1, 1, 0},
          bases: {:1, :2, :3, :0}
      end

  """

  defmacro __using__(opts) do
    module = __CALLER__.module

    signature =
      opts
      |> Keyword.fetch!(:signature)
      |> Code.eval_quoted([], __CALLER__)
      |> case do
        {signature, _} -> signature
      end

    bases =
      opts
      |> Keyword.get(:bases)
      |> then(&if(&1, do: Code.eval_quoted(&1, [], __CALLER__)))
      |> case do
        nil -> for i <- 1..tuple_size(signature), do: i
        {b, _} -> b
      end

    if tuple_size(bases) != tuple_size(signature) do
      raise "number of bases (given #{inspect(bases)}) must be the same as the size of the signature (given #{inspect(signature)})"
    end

    table = Table.build(signature)

    dimension = tuple_size(signature)
    size = Bitwise.bsl(1, dimension)

    basis_names = Galixir.Generator.basis_names(bases)

    blade_indices = Galixir.Generator.blade_indices(bases)
    blade_aliases = Galixir.Generator.blade_aliases(bases)
    new_impl = Galixir.Generator.New.new_impl(size)

    q =
      quote do
        defstruct [:data]

        @signature unquote(Macro.escape(signature))
        @table unquote(Macro.escape(table))
        @size unquote(size)
        @blade_indices unquote(Macro.escape(blade_indices))
        @blade_aliases unquote(Macro.escape(blade_aliases))

        @doc """
        Returns the number of coefficients stored by the algebra.

        A dimension `n` algebra contains `2^n` basis blades.
        """
        def size() do
          @size
        end

        @doc """
        Returns the dimension of the algebra.

        This is the number of basis vectors defined by the signature.
        """
        def dimension do
          tuple_size(@signature)
        end

        @doc """
        Returns the metric signature of the algebra.

        Example:

            {1, 1, 1, 0}

        represents a projective geometric algebra with three Euclidean basis
        vectors and one null basis vector.
        """
        def signature do
          @signature
        end

        @doc """
        Returns the multiplication table for the algebra.

        The table contains precomputed geometric products between basis blades.
        Each entry maps `{left_blade, right_blade}` to `{coefficient, result_blade}`.

        The blades are represented internally as bitmasks.

        ## Example

            iex> #{inspect(__MODULE__)}.table() |> Map.has_key?({#{unquote(elem(bases, 0))}, #{unquote(elem(bases, 0))}})
            #{unquote(elem(signature, 0) != 0)}
        """
        def table do
          @table
        end

        @doc """
        Returns the mapping between blade names and storage indices.

        Blade coefficients are stored in a fixed-size tuple. This map translates
        canonical blade names into their corresponding tuple index.

        ## Example

            iex> #{inspect(__MODULE__)}.blade_indices()[:e#{unquote(elem(bases, 0))}]
            1
        """
        def blade_indices do
          @blade_indices
        end

        unquote(new_impl)

        unquote(Galixir.Generator.Cofficients.coefficient_impl(module, bases))

        unquote_splicing(
          Galixir.Generator.GeometricProduct.geometric_product_impl(table, size, bases, signature)
        )

        unquote(Galixir.Generator.WedgeProduct.wedge_product_impl(dimension, signature, bases))

        unquote_splicing(Galixir.Generator.LinearOps.linear_ops_impl(size))
        unquote(Galixir.Generator.Reverse.reverse_impl(size, bases))
        unquote(Galixir.Generator.Dual.dual_impl(dimension, bases))
        unquote(Galixir.Generator.Grade.grade_impl(dimension, bases))
        unquote(Galixir.Generator.Grade.grades_impl(dimension, bases))
        unquote(Galixir.Generator.Canonical.max_abs_component_impl(dimension, module, bases))
        unquote(Galixir.Generator.Canonical.canonical_sign_impl(dimension, module, bases))
        unquote(Galixir.Generator.Predicates.zero_check_impl(dimension, bases))
        unquote(Galixir.Generator.InnerProduct.inner_product_impl(signature, bases, :inner))
        unquote(Galixir.Generator.InnerProduct.inner_product_impl(signature, bases, :left))
        unquote(Galixir.Generator.InnerProduct.inner_product_impl(signature, bases, :right))
        unquote(Galixir.Generator.ScalarProduct.scalar_product_impl(dimension, signature, bases))

        unquote(Galixir.Generator.Inspect.inspect_impl(bases))

        unquote(Galixir.Generator.Predicates.scalar_check_impl(dimension, bases))

        unquote_splicing(basis_names)

        unquote(Inverse.inverse_impl(signature, bases))

        unquote(Predicates.blade_check_impl(bases))

        unquote(Galixir.Generator.Norm.norm_impl())

        def commutator(a, b) do
          scale(
            0.5,
            sub(gp(a, b), gp(b, a))
          )
        end

        def wedge_all(vectors) do
          Enum.reduce(vectors, fn v, acc ->
            wedge(acc, v)
          end)
        end

        def rotor_between_frames(source, target) do
          source_blade = wedge_all(source)
          target_blade = wedge_all(target)

          x =
            gp(
              target_blade,
              blade_inverse(source_blade)
            )

          normalize(
            add(
              new(scalar: 1),
              x
            )
          )
        end
      end

    q
  end
end
