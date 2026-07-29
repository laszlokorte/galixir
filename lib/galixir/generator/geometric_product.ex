defmodule Galixir.Generator.GeometricProduct do
  import Galixir.Generator.Utils, only: [sum: 1]
  alias Galixir.Table
  alias Galixir.GeneratorBehaviour
  @behaviour GeneratorBehaviour
  @impl GeneratorBehaviour
  def generate_implementation(%Galixir.Meta{table: t, bases: b, metric: metric}) do
    blade_count = Table.blade_count(metric)
    geometric_product_impl(t, blade_count, b, metric)
  end

  def geometric_product_impl(table, blade_count, bases, metric) do
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
                (unquote(ca) * unquote(cb)) |> Galixir.negate_coefficient()
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

    result_tuple =
      {:{}, [], result}

    first_blade = "e#{elem(bases, 0)}"
    first_matric = elem(metric, 0)

    [
      quote do
        @doc """
        Computes the geometric product of two multivectors.

        The geometric product is the fundamental multiplication operation of
        geometric algebra. It combines the outer product and metric-dependent
        inner product into a single associative operation.

        The result depends on the algebra's metric.

        ## Examples

            iex> gp(
            ...>   new(#{unquote(first_blade)}: 1),
            ...>   new(#{unquote(first_blade)}: 1)
            ...> )
            new(scalar: #{unquote(first_matric)})

        """
        def gp(%__MODULE__{data: lhs}, %__MODULE__{data: rhs}) do
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
