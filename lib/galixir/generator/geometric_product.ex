defmodule Galixir.Generator.GeometricProduct do
  import Galixir.Generator.Utils, only: [sum: 1]

  def geometric_product_impl(table, size) do
    lhs = Macro.var(:lhs, nil)

    rhs = Macro.var(:rhs, nil)

    terms =
      for {{a, b}, {coef, result}} <- table,
          coef != 0 do
        ca =
          quote do
            elem(unquote(lhs), unquote(a))
          end

        cb =
          quote do
            elem(unquote(rhs), unquote(b))
          end

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
      end

    result =
      for index <- 0..(size - 1) do
        terms
        |> Enum.filter(fn {r, _} -> r == index end)
        |> Enum.map(fn {_, t} -> t end)
        |> sum()
      end

    result_tuple =
      {:{}, [], result}

    [
      quote do
        def gp(%__MODULE__{data: lhs}, %__MODULE{data: rhs}) do
          %__MODULE__{data: gp(lhs, rhs)}
        end
      end,
      quote do
        def gp(unquote(lhs), unquote(rhs)) do
          unquote(result_tuple)
        end
      end
    ]
  end
end
