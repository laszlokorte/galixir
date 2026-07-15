defmodule Galixir.Generator.Reverse do
  import Galixir.Generator.Utils, only: [vars: 2, tuple_ast: 1, blade_grade: 1, reverse_sign: 1]

  def reverse_impl(size) do
    a = vars(:a, size)

    result =
      for mask <- 0..(size - 1) do
        sign = reverse_sign(blade_grade(mask))

        if sign == 1 do
          Enum.at(a, mask)
        else
          quote do
            -unquote(Enum.at(a, mask))
          end
        end
      end

    quote do
      def reverse(%__MODULE__{data: d}) do
        %__MODULE__{data: reverse(d)}
      end

      def reverse(unquote(tuple_ast(a))) do
        unquote(tuple_ast(result))
      end
    end
  end
end
