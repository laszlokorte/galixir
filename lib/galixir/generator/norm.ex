defmodule Galixir.Generator.Norm do
  @moduledoc """
  Generates multivector norm, normalization, and canonicalization functions.
  """

  alias Galixir.GeneratorBehaviour
  @behaviour GeneratorBehaviour
  @impl GeneratorBehaviour
  def generate_implementation(%Galixir.Meta{}) do
    [
      norm_impl()
    ]
  end

  def norm_impl() do
    quote do
      @doc """
      Returns the squared norm of a multivector.

      The squared norm is computed as:

          scalar_part(a * reverse(a))

      The result may be negative for algebras with indefinite metrics.

      This is also called the Spinor Magnitude.

      ## Example

          iex> a = new(scalar: 3)
          iex> squared_norm(a)
          9.0
      """

      @doc group: :norm
      def squared_norm(%__MODULE__{} = a) do
        scalar_part(gp(a, reverse(a)))
      end

      @doc """
      Returns the norm of a multivector.

      The norm is the square root of the absolute squared norm.

      ## Example

          iex> a = new(scalar: 3)
          iex> norm(a)
          3.0
      """

      @doc group: :norm
      def norm(%__MODULE__{} = a) do
        abs(squared_norm(a)) ** 0.5
      end

      @doc """
      Normalizes a multivector.

      The result has unit norm while preserving the direction of the
      multivector.

      Raises `ArgumentError` when attempting to normalize a null
      multivector.

      ## Example

          iex> a = new(scalar: 2)
          iex> norm(normalize!(a))
          1.0

          iex> normalize!(new())
          ** (ArgumentError) cannot normalize given null multivector ...

          iex> normalize!(new(scalar: epsilon() / 2.0))
          ** (ArgumentError) cannot normalize given null multivector ...
      """

      @doc group: :norm
      def normalize!(%__MODULE__{} = a) do
        normalize(a)
        |> case do
          {:ok, result} ->
            result

          :error ->
            raise ArgumentError, "cannot normalize given null multivector (#{inspect(a)})"
        end
      end

      @doc group: :norm
      def normalize(%__MODULE__{} = a) do
        n2 = squared_norm(a)

        if above_epsilon?(n2) do
          {:ok, scale(1 / abs(n2) ** 0.5, a)}
        else
          :error
        end
      end

      @doc group: :norm
      def canonicalize!(%__MODULE__{} = a) do
        canonicalize(a)
        |> case do
          {:error, :no_blade} ->
            raise ArgumentError, "can only canonicalize blades, given: (#{inspect(a)})"

          {:error, :zero} ->
            raise ArgumentError, "cannot canonicalize zero multivector, given: (#{inspect(a)})"

          {:ok, r} ->
            r
        end
      end

      @doc group: :norm
      def canonicalize(%__MODULE__{} = a) do
        case {blade?(a), max_abs_component(a)} do
          {false, _} ->
            {:error, :no_blade}

          {_, m} when not is_above_epsilon(m) ->
            {:error, :zero}

          {_, max} ->
            {:ok, scale(canonical_sign(a) / max, a)}
        end
      end
    end
  end
end
