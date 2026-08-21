defmodule Galixir.Generator.Conversion do
  @behaviour Galixir.GeneratorBehaviour
  @impl Galixir.GeneratorBehaviour
  def generate_implementation(%Galixir.Meta{}) do
    [
      conversion_impl()
    ]
  end

  def conversion_impl() do
    quote do
      @doc """
      Turns a Multivector with only a scalar part into an elixir number.

      Raises if the given Multivector is not grade 0.

      iex> ~G[3.0] |> to_scalar()
      3.0

      iex> ~G[3.0 + e1] |> to_scalar()
      ** (ArgumentError) cannot convert multivector to scalar: only grade-0 multivectors can be converted to a scalar, got ...
      """
      def to_scalar(mv) do
        if scalar?(mv) do
          scalar_part(mv)
        else
          raise ArgumentError,
                "cannot convert multivector to scalar: only grade-0 multivectors can be converted to a scalar, got #{inspect(mv)}"
        end
      end

      @doc """
      Turns a Multivector with only a scalar part into an elixir number.

          iex> ~G[3.0] |> scalar()
          {:ok, 3.0}

          iex> ~G[3.0 + e1] |> scalar()
          :error
      """
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
