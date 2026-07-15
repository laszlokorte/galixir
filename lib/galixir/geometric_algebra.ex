defmodule Galixir.GeometricAlgebra do
  alias Galixir.Table

  defmacro __using__(opts) do
    signature_ast =
      opts
      |> Keyword.fetch!(:signature)

    {signature, _} = Code.eval_quoted(signature_ast, [], __CALLER__)
    signature = signature |> Tuple.to_list()

    table = Table.build(signature)

    dimension = length(signature)
    size = Bitwise.bsl(1, dimension)

    gp =
      Galixir.Generator.GeometricProduct.geometric_product_impl(table, size)

    wedge =
      Galixir.Generator.WedgeProduct.wedge_product_impl(dimension, signature)

    scalar_product =
      Galixir.Generator.ScalarProduct.scalar_product_impl(dimension, signature)

    linear_ops =
      Galixir.Generator.LinearOps.linear_ops_impl(size)

    reverse =
      Galixir.Generator.Reverse.reverse_impl(size)

    dual =
      Galixir.Generator.Dual.dual_impl(dimension, signature)

    grade =
      Galixir.Generator.Grade.grade_impl(dimension)

    inner =
      Galixir.Generator.InnerProduct.inner_product_impl(signature)

    scalar =
      Galixir.Generator.Predicates.scalar_check_impl(dimension)

    zero =
      Galixir.Generator.Predicates.zero_check_impl(dimension)

    grades =
      Galixir.Generator.Grade.grades_impl(dimension)

    max_abs =
      Galixir.Generator.Canonical.max_abs_component_impl(dimension)

    canon_sign =
      Galixir.Generator.Canonical.canonical_sign_impl(dimension)

    inspect = Galixir.Generator.Inspect.inspect_impl(__CALLER__.module)
    basis_names = Galixir.Generator.basis_names(size)
    blade_indices = Galixir.Generator.blade_indices(dimension)

    quote do
      defstruct [:data]

      @signature unquote(signature)
      @table unquote(Macro.escape(table))
      @size unquote(size)
      @blade_indices unquote(Macro.escape(blade_indices))

      def new(basis \\ [])

      def new(data) when is_tuple(data) and tuple_size(data) == unquote(size) do
        %__MODULE__{data: data}
      end

      def new(fields) when is_list(fields) do
        coeffs = :erlang.make_tuple(@size, 0)

        coeffs =
          Enum.reduce(fields, coeffs, fn {blade, coef}, acc ->
            index =
              Map.fetch!(@blade_indices, blade)

            put_elem(acc, index, coef)
          end)

        %__MODULE__{data: coeffs}
      end

      def coefficient(%__MODULE__{data: data}, blade) do
        index = Map.fetch!(@blade_indices, blade)
        elem(data, index)
      end

      def size() do
        @size
      end

      def dimension do
        length(@signature)
      end

      def signature do
        @signature
      end

      unquote_splicing(gp)
      unquote(wedge)

      unquote_splicing(linear_ops)
      unquote(reverse)
      unquote(dual)
      unquote(grade)
      unquote(max_abs)
      unquote(zero)
      unquote(grades)
      unquote(inner)
      unquote(scalar_product)
      unquote(canon_sign)

      unquote(inspect)

      def inverse(%__MODULE__{} = a) do
        rev = reverse(a)

        product = gp(a, rev)

        unless scalar?(product) do
          raise ArgumentError,
                "multivector is not invertible by reverse formula"
        end

        denominator =
          product.data
          |> elem(0)

        if denominator == 0 do
          raise ArgumentError,
                "multivector is not invertible"
        end

        scale(1 / denominator, rev)
      end

      unquote(scalar)

      unquote_splicing(basis_names)

      def blade?(%__MODULE__{} = a) do
        length(grades(a)) <= 1
      end

      def normalize(%__MODULE__{} = a) do
        unless blade?(a) do
          raise ArgumentError, "can only normalize blades"
        end

        max = max_abs_component(a)

        if max == 0 do
          raise ArgumentError, "cannot normalize zero multivector"
        end

        scale(canonical_sign(a) / max, a)
      end

      def squared_norm(%__MODULE__{} = a) do
        scalar_product(a, reverse(a))
      end

      def norm(%__MODULE__{} = a) do
        :math.sqrt(abs(squared_norm(a)))
      end

      def scalar_part(%__MODULE__{data: data}) do
        elem(data, 0)
      end

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

      def blade_inverse(b) do
        rev = reverse(b)

        n =
          scalar_part(gp(b, rev))

        if abs(n) < 1.0e-12 do
          raise "cannot invert null blade"
        end

        scale(1 / n, rev)
      end

      def normalize_blade(b) do
        n2 =
          scalar_part(gp(b, reverse(b)))

        if abs(n2) < 1.0e-12 do
          raise "cannot normalize null blade"
        end

        scale(1 / :math.sqrt(abs(n2)), b)
      end
    end
  end
end
