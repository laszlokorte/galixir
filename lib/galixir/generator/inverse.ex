defmodule Galixir.Generator.Inverse do
  @moduledoc """
  Generates inverse operations based on multivector reversion.
  """

  alias Galixir.GeneratorBehaviour
  @behaviour GeneratorBehaviour
  @impl GeneratorBehaviour
  def generate_implementation(%Galixir.Meta{metric: metric, bases: bases}) do
    [
      inverse_impl(metric, bases)
    ]
  end

  def inverse_impl(metric, bases) do
    first_blade = "e#{elem(bases, 0)}"
    metric = elem(metric, 0)

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
                  iex> inverse(
                  ...>   new(#{unquote(first_blade)}: 2)
                  ...> )|> inspect
                  new(#{unquote(first_blade)}: #{unquote(2 / metric / 4)}) |> inspect

                  iex> inverse!(
                  ...>   new(#{unquote(first_blade)}: 2)
                  ...> )|> inspect
                  new(#{unquote(first_blade)}: #{unquote(2 / metric / 4)}) |> inspect
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
                ...>   inverse!(new(#{unquote(first_blade)}: 1))
                ...> end

                iex> inverse(new(#{unquote(first_blade)}: 1))
                ...> :invalid
          """
        end
      end

    quote do
      unquote(doc)

      def inverse!(%__MODULE__{} = a) do
        inverse(a)
        |> case do
          :invalid ->
            raise ArgumentError,
                  "multivector (#{inspect(a)}) is not invertible"

          res ->
            res
        end
      end

      def inverse(%__MODULE__{} = a) do
        rev = reverse(a)

        with product <- gp(a, rev),
             true <- scalar?(product) == true,
             denom <- scalar_part(product),
             true <- denom != 0.0 do
          scale(1 / denom, rev)
        else
          _ ->
            :invalid
        end
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
