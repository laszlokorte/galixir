defmodule Galixir.GeometricAlgebra do
  alias Galixir.Generator.Inverse
  alias Galixir.Generator.Predicates
  alias Galixir.Table

  defmacro __using__(opts) do
    signature =
      opts
      |> Keyword.fetch!(:signature)
      |> Code.eval_quoted([], __CALLER__)
      |> case do
        {signature, _} -> signature |> Tuple.to_list()
      end

    bases =
      opts
      |> Keyword.get(:bases)
      |> then(&if(&1, do: Code.eval_quoted(&1, [], __CALLER__)))
      |> case do
        nil -> for i <- 1..Enum.count(signature), do: i
        {b, _} -> b |> Tuple.to_list()
      end

    if Enum.count(bases) != Enum.count(signature) do
      raise "number of bases (given #{inspect(bases)}) must be the same as the size of the signature (given #{signature})"
    end

    table = Table.build(signature)

    dimension = length(signature)
    size = Bitwise.bsl(1, dimension)

    basis_names = Galixir.Generator.basis_names(bases)

    blade_indices = Galixir.Generator.blade_indices(bases)
    blade_aliases = Galixir.Generator.blade_aliases(bases)
    new_impl = Galixir.Generator.New.new_impl(size)

    quote do
      defstruct [:data]

      @signature unquote(signature)
      @table unquote(Macro.escape(table))
      @size unquote(size)
      @blade_indices unquote(Macro.escape(blade_indices))
      @blade_aliases unquote(Macro.escape(blade_aliases))

      def size() do
        @size
      end

      def dimension do
        length(@signature)
      end

      def signature do
        @signature
      end

      def blade_indices do
        @blade_indices
      end

      unquote(new_impl)

      unquote(Galixir.Generator.Cofficients.coefficient_impl())

      unquote_splicing(Galixir.Generator.GeometricProduct.geometric_product_impl(table, size))
      unquote(Galixir.Generator.WedgeProduct.wedge_product_impl(dimension, signature))

      unquote_splicing(Galixir.Generator.LinearOps.linear_ops_impl(size))
      unquote(Galixir.Generator.Reverse.reverse_impl(size))
      unquote(Galixir.Generator.Dual.dual_impl(dimension))
      unquote(Galixir.Generator.Grade.grade_impl(dimension))
      unquote(Galixir.Generator.Canonical.max_abs_component_impl(dimension))
      unquote(Galixir.Generator.Predicates.zero_check_impl(dimension))
      unquote(Galixir.Generator.Grade.grades_impl(dimension))
      unquote(Galixir.Generator.InnerProduct.inner_product_impl(signature))
      unquote(Galixir.Generator.ScalarProduct.scalar_product_impl(dimension, signature))
      unquote(Galixir.Generator.Canonical.canonical_sign_impl(dimension))

      unquote(Galixir.Generator.Inspect.inspect_impl())

      unquote(Galixir.Generator.Predicates.scalar_check_impl(dimension))

      unquote_splicing(basis_names)

      unquote(Inverse.inverse_impl())

      unquote(Predicates.blade_check_impl())

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
  end
end
