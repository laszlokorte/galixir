defmodule Galixir.Generator.Inverse do
  def inverse_impl(signature, bases) do
    first_blade = "e#{elem(bases, 0)}"
    metric = elem(signature, 0)

    doc =
      if metric != 0 do
        quote do
          @doc """
            Computes the inverse of a multivector.

            The inverse is computed using the reverse:

            inverse(a) = reverse(a) / scalar_part(a * reverse(a))

            This formula is valid when `a * reverse(a)` is a non-zero scalar.

            Raises `ArgumentError` if the multivector is not invertible by this formula.


              ## Examples

                  iex> #{inspect(__MODULE__)}.inverse(
                  ...>   #{inspect(__MODULE__)}.new(#{unquote(first_blade)}: 2)
                  ...> )|> inspect
                  #{inspect(__MODULE__)}.new(#{unquote(first_blade)}: #{unquote(2 / metric / 4)}) |> inspect
          """
        end
      else
        quote do
          @doc """
            Computes the inverse of a multivector.

            The inverse is computed using the reverse:

            inverse(a) = reverse(a) / scalar_part(a * reverse(a))

            This formula is valid when `a * reverse(a)` is a non-zero scalar.

            Raises `ArgumentError` if the multivector is not invertible by this formula.

              ## Examples

                  iex> assert_raise ArgumentError, fn ->
                  ...>   #{inspect(__MODULE__)}.inverse(#{inspect(__MODULE__)}.new(#{unquote(first_blade)}: 1))
                  ...> end
          """
        end
      end

    quote do
      unquote(doc)

      def inverse(%__MODULE__{} = a) do
        rev = reverse(a)

        product = gp(a, rev)

        unless scalar?(product) do
          raise ArgumentError,
                "given multivector (#{inspect(a)}) is not invertible by reverse formula"
        end

        denominator =
          product.data
          |> elem(0)

        if denominator == 0 do
          raise ArgumentError,
                "multivector (#{inspect(a)}) is not invertible"
        end

        scale(1 / denominator, rev)
      end

      def blade_inverse(b) do
        rev = reverse(b)

        n =
          scalar_part(gp(b, rev))

        if abs(n) < 1.0e-12 do
          raise "cannot invert null blade (#{inspect(b)})"
        end

        scale(1 / n, rev)
      end
    end
  end
end
