defmodule Galixir.Generator.Predicates do
  alias Galixir.Chain
  import Galixir.Generator.Utils, only: [tuple_ast: 1]

  def scalar_check_impl(dimension) do
    blade_count = Bitwise.bsl(1, dimension)

    a =
      for i <- 0..(blade_count - 1) do
        if i == 0 do
          nil
        else
          Macro.var(:"a#{i}", nil)
        end
      end

    quote do
      def scalar?(%__MODULE__{data: d}) do
        scalar?(d)
      end

      def scalar?(unquote(tuple_ast(a)), eps \\ 1.0e-12) do
        unquote(
          Enum.map(1..(blade_count - 1), &Enum.at(a, &1))
          |> Enum.map(&quote(do: abs(unquote(&1)) < eps))
          |> Chain.and_chain()
        )
      end
    end
  end

  def zero_check_impl(dimension) do
    blade_count = Bitwise.bsl(1, dimension)

    a =
      for i <- 0..(blade_count - 1) do
        Macro.var(:"a#{i}", nil)
      end

    checks =
      for i <- 0..(blade_count - 1) do
        quote do
          unquote(Enum.at(a, i)) == 0
        end
      end

    condition = checks |> Chain.and_chain()

    quote do
      def zero?(%__MODULE__{data: d}) do
        zero?(d)
      end

      def zero?(unquote(tuple_ast(a))) do
        unquote(condition)
      end
    end
  end

  def blade_check_impl do
    quote do
      def blade?(%__MODULE__{} = a) do
        Enum.count(grades(a)) <= 1
      end
    end
  end
end
