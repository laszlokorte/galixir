defmodule Galixir.Generator.Inverse do
  @moduledoc """
  Generates inverse operations using reversion when the reverse product is scalar.
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

          The reverse product must pass `scalar?/1` and its scalar coefficient
          must exceed `epsilon/0` in absolute value. Raises `ArgumentError`
          otherwise.

          ## Examples

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

          The reverse product must pass `scalar?/1` and its scalar coefficient
          must exceed `epsilon/0` in absolute value. Raises `ArgumentError`
          otherwise.

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

          The reverse product must pass `scalar?/1` (which has its own fixed
          tolerance), and its scalar coefficient must exceed `epsilon/0` in
          absolute value. Returns `{:ok, result}` if both checks pass, or
          `:error` otherwise.

          ## Examples

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

          `inverse(a) = reverse(a) / scalar_part(a * reverse(a))`

          Returns `{:ok, result}` when the reverse product passes `scalar?/1`
          and its scalar coefficient exceeds `epsilon/0` in absolute value;
          otherwise returns `:error`.

          ## Examples

              iex> inverse(
              ...>   new(scalar: 2)
              ...> )
              {:ok, new(scalar: 0.5)}

              iex> inverse(new(#{unquote(first_blade)}: 1))
              :error
          """
        end
      end

    quote do
      unquote(doc!)

      @doc group: :inverse
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

      @doc group: :inverse
      def inverse(%__MODULE__{} = a) do
        with rev <- reverse(a),
             product <- gp(a, rev),
             {:ok, denom} when is_above_epsilon(denom) <- scalar(product) do
          {:ok, scale(1 / denom, rev)}
        else
          _ -> :error
        end
      end

      @doc """
      Computes `reverse(b) / scalar_part(b * reverse(b))`.

      Intended for a non-null simple blade, whose reverse product is scalar.
      Unlike `inverse!/1`, this does not check that the reverse product is
      scalar; it only checks that its scalar part exceeds `epsilon/0` in
      absolute value and raises `ArgumentError` otherwise.
      """
      @doc group: :inverse
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
