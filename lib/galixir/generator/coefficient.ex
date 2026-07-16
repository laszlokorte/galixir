defmodule Galixir.Generator.Cofficients do
  def coefficient_impl do
    quote do
      def coefficient(%__MODULE__{data: data}, blade) do
        {canonical, sign} =
          Map.get(@blade_aliases, blade, {blade, 1})

        sign * elem(data, Map.fetch!(@blade_indices, canonical))
      end

      def scalar_part(%__MODULE__{data: data}) do
        elem(data, 0)
      end
    end
  end
end
