defmodule Galixir.Generator.Norm do
  def norm_impl() do
    quote do
      def squared_norm(%__MODULE__{} = a) do
        scalar_part(gp(a, reverse(a)))
      end

      def norm(%__MODULE__{} = a) do
        :math.sqrt(abs(squared_norm(a)))
      end

      def normalize(%__MODULE__{} = a) do
        n2 = squared_norm(a)

        if abs(n2) < 1.0e-12 do
          raise ArgumentError, "cannot normalize null multivector"
        end

        scale(1 / :math.sqrt(abs(n2)), a)
      end

      def canonicalize(%__MODULE__{} = a) do
        unless blade?(a) do
          raise ArgumentError, "can only canonicalize blades"
        end

        max = max_abs_component(a)

        if max == 0 do
          raise ArgumentError, "cannot canonicalize zero multivector"
        end

        scale(canonical_sign(a) / max, a)
      end
    end
  end
end
