defmodule Galixir.Generator.InnerProduct do
  import Galixir.Generator.Utils, only: [vars: 2, sum: 1, blade_grade: 1, tuple_ast: 1]

  def inner_product_impl(signature) do
    dimension = tuple_size(signature)
    blade_count = Bitwise.bsl(1, dimension)

    lhs = vars(:lhs, blade_count)
    rhs = vars(:rhs, blade_count)

    terms =
      for a <- 0..(blade_count - 1),
          b <- 0..(blade_count - 1) do
        {coef, result} =
          Galixir.Blade.multiply(
            a,
            b,
            signature
          )

        if coef != 0 and
             blade_grade(result) ==
               abs(blade_grade(a) - blade_grade(b)) do
          ca = Enum.at(lhs, a)
          cb = Enum.at(rhs, b)

          term =
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

          {result, term}
        else
          nil
        end
      end
      |> Enum.reject(&is_nil/1)

    result =
      for index <- 0..(blade_count - 1) do
        terms
        |> Enum.filter(fn {r, _} -> r == index end)
        |> Enum.map(fn {_, t} -> t end)
        |> sum()
      end

    quote do
      def inner(%__MODULE__{data: a}, %__MODULE__{data: b}) do
        %__MODULE__{data: inner(a, b)}
      end

      def inner(unquote(tuple_ast(lhs)), unquote(tuple_ast(rhs))) do
        unquote(tuple_ast(result))
      end
    end
  end
end
