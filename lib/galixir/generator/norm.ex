defmodule Galixir.Generator.Norm do
  def norm_impl() do
    quote do
      @doc """
      Returns the squared norm of a multivector.

      The squared norm is computed as:

          scalar_part(a * reverse(a))

      The result may be negative for algebras with indefinite metrics.

      ## Example

          iex> a = #{inspect(__MODULE__)}.new(scalar: 3)
          iex> #{inspect(__MODULE__)}.squared_norm(a)
          9.0
      """
      def squared_norm(%__MODULE__{} = a) do
        scalar_part(gp(a, reverse(a)))
      end

      @doc """
      Returns the norm of a multivector.

      The norm is the square root of the absolute squared norm.

      ## Example

          iex> a = #{inspect(__MODULE__)}.new(scalar: 3)
          iex> #{inspect(__MODULE__)}.norm(a)
          3.0
      """
      def norm(%__MODULE__{} = a) do
        :math.sqrt(abs(squared_norm(a)))
      end

      @doc """
      Normalizes a multivector.

      The result has unit norm while preserving the direction of the
      multivector.

      Raises `ArgumentError` when attempting to normalize a null
      multivector.

      ## Example

          iex> a = #{inspect(__MODULE__)}.new(scalar: 2)
          iex> #{inspect(__MODULE__)}.norm(#{inspect(__MODULE__)}.normalize(a))
          1.0
      """
      def normalize(%__MODULE__{} = a) do
        n2 = squared_norm(a)

        if abs(n2) < 1.0e-12 do
          raise ArgumentError, "cannot normalize given null multivector (#{inspect(a)})"
        end

        scale(1 / :math.sqrt(abs(n2)), a)
      end

      def canonicalize(%__MODULE__{} = a) do
        unless blade?(a) do
          raise ArgumentError, "can only canonicalize blades, given: (#{inspect(a)})"
        end

        max = max_abs_component(a)

        if max == 0 do
          raise ArgumentError, "cannot canonicalize zero multivector, given: (#{inspect(a)})"
        end

        scale(canonical_sign(a) / max, a)
      end
    end
  end
end
