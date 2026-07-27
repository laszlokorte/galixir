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

    blade_indices = Galixir.Generator.blade_indices(bases)
    blade_aliases = Galixir.Generator.blade_aliases(bases)

    meta = %Galixir.Meta{
      module: module,
      dimensions: dimension,
      size: size,
      signature: signature,
      bases: bases,
      table: table,
      blade_indices: blade_indices,
      blade_aliases: blade_aliases
    }

    quote do
      defstruct [:data]

      unquote_splicing(
        for g <- Galixir.GeneratorRegistry.generators() do
          g.generate_implementation(meta)
        end
      )

      def commutator(a, b) do
        scale(
          0.5,
          sub(gp(a, b), gp(b, a))
        )
      end

      @doc """
      Computes the outer product of a list of multivectors.

      The vectors are combined from left to right using the wedge product.

      The result is a blade representing the subspace spanned by all input
      multivectors.
      """

      def wedge_all(vectors) do
        Enum.reduce(vectors, new(), fn v, acc ->
          wedge(acc, v)
        end)
      end

      @doc """
      Computes the rotor that maps one frame to another.

      The function constructs blades from the source and target frames and computes
      the transformation rotor:

      `R = normalize(1 + T * S⁻¹)`

      where `S` is the source frame blade and `T` is the target frame blade.

      The resulting rotor can be applied to multivectors to rotate the source frame
      into the target frame.

      """
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
  end
end
