defmodule Galixir.Generator.WedgeProduct do
  import Galixir.Generator.Utils, only: [vars: 2, sum: 1, tuple_ast: 1]

  def wedge_product_impl(dimension, signature) do
    blade_count = Bitwise.bsl(1, dimension)

    lhs = vars(:lhs, blade_count)
    rhs = vars(:rhs, blade_count)

    terms =
      for a <- 0..(blade_count - 1),
          b <- 0..(blade_count - 1),
          Bitwise.band(a, b) == 0 do
        {sign, result} =
          Galixir.Blade.multiply(
            a,
            b,
            signature
          )

        ca = Enum.at(lhs, a)
        cb = Enum.at(rhs, b)

        term =
          case sign do
            1 ->
              quote do
                unquote(ca) * unquote(cb)
              end

            -1 ->
              quote do
                -(unquote(ca) * unquote(cb))
              end
          end

        {result, term}
      end

    result =
      for index <- 0..(blade_count - 1) do
        terms
        |> Enum.filter(fn {r, _} -> r == index end)
        |> Enum.map(fn {_, t} -> t end)
        |> sum()
      end

    quote do
      def wedge(%__MODULE__{data: a}, %__MODULE__{data: b}) do
        %__MODULE__{data: wedge(a, b)}
      end

      def wedge(unquote(tuple_ast(lhs)), unquote(tuple_ast(rhs))) do
        unquote(tuple_ast(result))
      end
    end
  end
end
