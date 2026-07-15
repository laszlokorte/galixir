defmodule Galixir.Generator.ScalarProduct do
  import Galixir.Generator.Utils, only: [tuple_ast: 1, sum: 1]

  def scalar_product_impl(dimension, signature) do
    blade_count = Bitwise.bsl(1, dimension)

    raw_terms =
      for a <- 0..(blade_count - 1),
          b <- 0..(blade_count - 1) do
        {coef, result} =
          Galixir.Blade.multiply(
            a,
            b,
            signature
          )

        if coef != 0 and result == 0 do
          {a, b, coef}
        else
          nil
        end
      end
      |> Enum.reject(&is_nil/1)

    used_lhs =
      raw_terms
      |> Enum.map(fn {a, _, _} -> a end)
      |> MapSet.new()

    used_rhs =
      raw_terms
      |> Enum.map(fn {_, b, _} -> b end)
      |> MapSet.new()

    lhs =
      for a <- 0..(blade_count - 1) do
        if MapSet.member?(used_lhs, a) do
          Macro.var(:"lhs#{a}", nil)
        else
          nil
        end
      end

    rhs =
      for b <- 0..(blade_count - 1) do
        if MapSet.member?(used_rhs, b) do
          Macro.var(:"rhs#{b}", nil)
        else
          nil
        end
      end

    terms =
      for {a, b, coef} <- raw_terms do
        ca = Enum.at(lhs, a)
        cb = Enum.at(rhs, b)

        case coef do
          1 ->
            quote do
              unquote(ca) * unquote(cb)
            end

          -1 ->
            quote do
              -(unquote(ca) * unquote(cb))
            end
        end
      end

    quote do
      def scalar_product(%__MODULE__{data: a}, %__MODULE__{data: b}) do
        scalar_product(a, b)
      end

      def scalar_product(unquote(tuple_ast(lhs)), unquote(tuple_ast(rhs))) do
        unquote(sum(terms))
      end
    end
  end
end
