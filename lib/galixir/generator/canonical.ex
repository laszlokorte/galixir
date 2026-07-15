defmodule Galixir.Generator.Canonical do
  import Galixir.Generator.Utils, only: [vars: 2, tuple_ast: 1]

  def max_abs_component_impl(dimension) do
    blade_count = Bitwise.bsl(1, dimension)

    a = vars(:a, blade_count)

    values =
      for i <- 0..(blade_count - 1) do
        quote do
          abs(unquote(Enum.at(a, i)))
        end
      end

    quote do
      def max_abs_component(%__MODULE__{data: d}) do
        max_abs_component(d)
      end

      def max_abs_component(unquote(tuple_ast(a))) do
        Enum.max([
          unquote_splicing(values)
        ])
      end
    end
  end

  def canonical_sign_impl(dimension) do
    blade_count = Bitwise.bsl(1, dimension)

    a = vars(:a, blade_count)

    clauses =
      for i <- 0..(blade_count - 1) do
        value = Enum.at(a, i)

        quote do
          if unquote(value) != 0 do
            if unquote(value) < 0 do
              -1
            else
              1
            end
          end
        end
      end

    quote do
      def canonical_sign(%__MODULE__{data: d}) do
        canonical_sign(d)
      end

      def canonical_sign(unquote(tuple_ast(a))) do
        result =
          [
            unquote_splicing(clauses)
          ]
          |> Enum.find(&(&1 != nil))

        result || 1
      end
    end
  end
end
