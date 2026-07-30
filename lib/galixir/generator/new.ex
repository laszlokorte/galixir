defmodule Galixir.Generator.New do
  @moduledoc """
  Generates constructors for multivectors.
  """

  alias Galixir.GeneratorBehaviour
  @behaviour GeneratorBehaviour
  @impl GeneratorBehaviour

  def generate_implementation(%Galixir.Meta{metric: metric}) do
    blade_count = Galixir.Table.blade_count(metric)

    [
      new_impl(blade_count)
    ]
  end

  def new_impl(blade_count) do
    quote do
      def new(basis \\ [])

      def new(data) when is_tuple(data) and tuple_size(data) == unquote(blade_count) do
        %__MODULE__{data: data}
      end

      def new(fields) when is_list(fields) do
        coeffs = :erlang.make_tuple(unquote(blade_count), 0.0)

        coeffs =
          Enum.reduce(fields, coeffs, fn {blade, coef}, acc ->
            {canonical, sign} =
              Map.get(@blade_aliases, blade, {blade, 1})

            index =
              Map.fetch!(@blade_indices, canonical)

            put_elem(acc, index, 1.0 * sign * coef + elem(acc, index))
          end)

        %__MODULE__{data: coeffs}
      end
    end
  end
end
