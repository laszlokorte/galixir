defmodule Galixir.Generator.Norm do
  def norm_impl() do
    quote do
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
