defmodule Galixir.Generator.Dual do
  import Galixir.Generator.Utils, only: [vars: 2, tuple_ast: 1, sum: 1]

  def dual_impl(dimension) do
    blade_count = Bitwise.bsl(1, dimension)
    full_mask = blade_count - 1

    a = vars(:a, blade_count)

    result =
      for out_mask <- 0..(blade_count - 1) do
        terms =
          for mask <- 0..(blade_count - 1),
              Bitwise.bxor(mask, full_mask) == out_mask do
            sign = Galixir.Blade.dual_sign(mask, dimension)

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

    undual_result = List.duplicate(nil, blade_count)

    undual_result =
      Enum.reduce(0..(blade_count - 1), undual_result, fn mask, acc ->
        complement = Bitwise.bxor(mask, full_mask)
        sign = Galixir.Blade.dual_sign(mask, dimension)

        value =
          if sign == 1 do
            Enum.at(a, complement)
          else
            quote(do: -unquote(Enum.at(a, complement)))
          end

        List.replace_at(acc, mask, value)
      end)

    quote do
      def dual(%__MODULE__{data: d}) do
        %__MODULE__{data: dual(d)}
      end

      def dual(unquote(tuple_ast(a))) do
        unquote(tuple_ast(result))
      end

      def undual(%__MODULE__{data: d}) do
        %__MODULE__{data: undual(d)}
      end

      def undual(unquote(tuple_ast(a))) do
        unquote(tuple_ast(undual_result))
      end
    end
  end
end
