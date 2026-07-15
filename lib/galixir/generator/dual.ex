defmodule Galixir.Generator.Dual do
  import Galixir.Generator.Utils, only: [vars: 2, tuple_ast: 1, sum: 1]

  def dual_impl(dimension, signature) do
    blade_count = Bitwise.bsl(1, dimension)
    full_mask = blade_count - 1

    a = vars(:a, blade_count)

    result =
      for out_mask <- 0..(blade_count - 1) do
        terms =
          for mask <- 0..(blade_count - 1),
              Bitwise.bxor(mask, full_mask) == out_mask do
            dual_mask = out_mask

            {sign, _} =
              Galixir.Blade.multiply(mask, dual_mask, signature)

            value = Enum.at(a, mask)

            if sign == 1 do
              value
            else
              quote do
                -unquote(value)
              end
            end
          end

        sum(terms)
      end

    quote do
      def dual(%__MODULE__{data: d}) do
        %__MODULE__{data: dual(d)}
      end

      def dual(unquote(tuple_ast(a))) do
        unquote(tuple_ast(result))
      end
    end
  end
end
