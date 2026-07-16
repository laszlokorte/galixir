defmodule Galixir.Generator.New do
  def new_impl(size) do
    quote do
      def new(basis \\ [])

      def new(data) when is_tuple(data) and tuple_size(data) == unquote(size) do
        %__MODULE__{data: data}
      end

      def new(fields) when is_list(fields) do
        coeffs = :erlang.make_tuple(@size, 0)

        coeffs =
          Enum.reduce(fields, coeffs, fn {blade, coef}, acc ->
            {canonical, sign} =
              Map.get(@blade_aliases, blade, {blade, 1})

            index =
              Map.fetch!(@blade_indices, canonical)

            put_elem(acc, index, sign * coef + elem(acc, index))
          end)

        %__MODULE__{data: coeffs}
      end
    end
  end
end
