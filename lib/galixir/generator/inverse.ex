defmodule Galixir.Generator.Inverse do
  def inverse_impl do
    quote do
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
