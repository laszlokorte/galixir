defmodule Galixir.Generator.Conversion do
  @moduledoc "Generates scalar conversion functions for multivectors."

  @behaviour Galixir.GeneratorBehaviour
  @impl Galixir.GeneratorBehaviour
  def generate_implementation(%Galixir.Meta{}) do
    [
      conversion_impl()
    ]
  end

  def conversion_impl do
    quote do
      @doc """
      Returns the scalar coefficient as an Elixir number.

      Raises `ArgumentError` if `scalar?/1` is false (non-scalar
      coefficients above its fixed `1.0e-12` threshold).

          iex> ~G[3.0] |> to_scalar()
          3.0

          iex> ~G[3.0 + e1] |> to_scalar()
          ** (ArgumentError) cannot convert multivector to scalar: only grade-0 multivectors can be converted to a scalar, got ...
      """

      @doc group: :scalar
      def to_scalar(mv) do
        if scalar?(mv) do
          scalar_part(mv)
        else
          raise ArgumentError,
                "cannot convert multivector to scalar: only grade-0 multivectors can be converted to a scalar, got #{inspect(mv)}"
        end
      end

      @doc """
      Returns `{:ok, coefficient}` if `scalar?/1` holds, or `:error` otherwise.
      This uses the same fixed tolerance as `scalar?/1`.

          iex> ~G[3.0] |> scalar()
          {:ok, 3.0}

          iex> ~G[3.0 + e1] |> scalar()
          :error
      """
      @doc group: :scalar
      def scalar(mv) do
        if scalar?(mv) do
          {:ok, scalar_part(mv)}
        else
          :error
        end
      end
    end
  end
end
