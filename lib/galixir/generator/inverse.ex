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

    doc! =
      if metric != 0 do
        quote do
          @doc """
          Computes the inverse of a multivector.

          The inverse is computed using the reverse:

          inverse!(a) = reverse(a) / scalar_part(a * reverse(a))

          This formula is valid when `a * reverse(a)` is a non-zero scalar.

          Raises `ArgumentError` if the multivector is not invertible by this formula.

          ## Examples

              iex> inverse!(
              ...>   new(#{unquote(first_blade)}: 2)
              ...> )
              new(#{unquote(first_blade)}: #{unquote(2 / metric / 4)})

              iex> inverse!(
              ...>   new(#{unquote(first_blade)}: 2)
              ...> )
              new(#{unquote(first_blade)}: #{unquote(2 / metric / 4)})

              iex> assert_raise ArgumentError, fn ->
              ...>   inverse!(new(scalar: 0))
              ...> end
          """
        end
      else
        quote do
          @doc """
          Computes the inverse of a multivector.

          The inverse is computed using the reverse:

          inverse!(a) = reverse(a) / scalar_part(a * reverse(a))

          This formula is valid when `a * reverse(a)` is a non-zero scalar.

          Raises `ArgumentError` if the multivector is not invertible by this formula.

          ## Examples

              iex> inverse!(
              ...>   new(scalar: 2)
              ...> )
              new(scalar: 0.5)

              iex> assert_raise ArgumentError, fn ->
              ...>   inverse!(new(#{unquote(first_blade)}: 1))
              ...> end

          """
        end
      end

    doc =
      if metric != 0 do
        quote do
          @doc """
          Computes the inverse of a multivector.

          The inverse is computed using the reverse:

          `inverse(a) = reverse(a) / scalar_part(a * reverse(a))`

          This formula is valid when `a * reverse(a)` is a non-zero scalar.

          Returns either `{:ok, result}` if inverse can be compute or :error otherwise

          ## Examples

              iex> inverse(
              ...>   new(#{unquote(first_blade)}: 2)
              ...> )
              {:ok, new(#{unquote(first_blade)}: #{unquote(2 / metric / 4)}) }

              iex> inverse(
              ...>   new(#{unquote(first_blade)}: 2)
              ...> )
              {:ok, new(#{unquote(first_blade)}: #{unquote(2 / metric / 4)})}

              iex> inverse(
              ...>   new(scalar: 0.0)
              ...> )
              :error
          """
        end
      else
        quote do
          @doc """
          Computes the inverse of a multivector.

          The inverse is computed using the reverse:

          `inverse!(a) = reverse(a) / scalar_part(a * reverse(a))`

          This formula is valid when `a * reverse(a)` is a non-zero scalar.

          Returns either `{:ok, result}` if inverse can be compute or `:error` otherwise

          ## Examples

              iex> inverse(
              ...>   new(scalar: 2)
              ...> )
              {:ok, new(scalar: 0.5)}

              iex> inverse(new(#{unquote(first_blade)}: 1))
              ...> :error
          """
        end
      end

    quote do
      unquote(doc!)

      def inverse!(%__MODULE__{} = a) do
        inverse(a)
        |> case do
          :error ->
            raise ArgumentError,
                  "multivector (#{inspect(a)}) is not invertible"

          {:ok, inv} ->
            inv
        end
      end

      unquote(doc)

      def inverse(%__MODULE__{} = a) do
        with rev <- reverse(a),
             product <- gp(a, rev),
             {:ok, denom} when is_above_epsilon(denom) <- scalar(product) do
          {:ok, scale(1 / denom, rev)}
        else
          _ -> :error
        end
      end

      def blade_inverse(b) do
        rev = reverse(b)

        n =
          scalar_part(gp(b, rev))

        if not above_epsilon?(n) do
          raise ArgumentError, "cannot invert null blade (#{inspect(b)})"
        end

        scale(1 / n, rev)
      end
    end
  end
end
