defmodule Galixir.Generator.Grade do
  import Galixir.Generator.Utils, only: [blade_grade: 1, tuple_ast: 1]

  def grade_impl(dimension) do
    blade_count = Bitwise.bsl(1, dimension)

    clauses =
      for wanted_grade <- 0..dimension do
        vars =
          for mask <- 0..(blade_count - 1) do
            if blade_grade(mask) == wanted_grade do
              Macro.var(:"a#{mask}", nil)
            else
              nil
            end
          end

        result =
          for mask <- 0..(blade_count - 1) do
            if blade_grade(mask) == wanted_grade do
              Enum.at(vars, mask)
            else
              quote do
                0
              end
            end
          end

        quote do
          def grade(unquote(tuple_ast(vars)), unquote(wanted_grade)) do
            unquote(tuple_ast(result))
          end
        end
      end

    quote do
      def grade(%__MODULE__{data: d}, g) do
        %__MODULE__{data: grade(d, g)}
      end

      unquote_splicing(clauses)

      def grade(t, r) when is_tuple(t) do
        raise ArgumentError, "invalid grade #{r} for given multivector (#{inspect(t)})"
      end
    end
  end

  def grades_impl(dimension) do
    blade_count = Bitwise.bsl(1, dimension)

    a =
      for i <- 0..(blade_count - 1) do
        Macro.var(:"a#{i}", nil)
      end

    grade_checks =
      for g <- 0..dimension do
        masks =
          for mask <- 0..(blade_count - 1),
              blade_grade(mask) == g do
            mask
          end

        condition =
          for mask <- masks do
            quote do
              unquote(Enum.at(a, mask)) != 0
            end
          end
          |> Galixir.Chain.or_chain()

        {g, condition}
      end

    body =
      for {g, condition} <- grade_checks do
        quote do
          if unquote(condition) do
            [unquote(g)]
          else
            []
          end
        end
      end

    quote do
      def grades(%__MODULE__{data: d}) do
        grades(d)
      end

      def grades(unquote(tuple_ast(a))) do
        [
          unquote_splicing(body)
        ]
        |> List.flatten()
      end
    end
  end
end
