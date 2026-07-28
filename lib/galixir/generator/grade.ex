defmodule Galixir.Generator.Grade do
  import Galixir.Generator.Utils, only: [blade_grade: 1, tuple_ast: 1]
  alias Galixir.Chain
  alias Galixir.GeneratorBehaviour
  @behaviour GeneratorBehaviour
  @impl GeneratorBehaviour
  def generate_implementation(%Galixir.Meta{
        dimensions: dim,
        bases: bases,
        blade_indices: blade_indices
      }) do
    [
      grade_impl(dim, bases),
      grades_impl(dim, bases),
      guard_impl(blade_indices)
    ]
  end

  def grade_impl(dimension, bases) do
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
                0.0
              end
            end
          end

        quote do
          def grade(unquote(tuple_ast(vars)), unquote(wanted_grade)) do
            unquote(tuple_ast(result))
          end
        end
      end

    first_blade = "e#{elem(bases, 0)}"

    quote do
      @doc """
      Extracts the grade-`g` component of a multivector.

      All coefficients whose basis blades are not of grade `g` are set to zero.

      Raises `ArgumentError` if `g` is outside the range `0..dimension()`.

      ## Examples

          iex> grade(
          ...>   new(scalar: 1, #{unquote(first_blade)}: 2),
          ...>   1
          ...> )
          new(#{unquote(first_blade)}: 2)

          iex> grade(
          ...>   new(scalar: 1, #{unquote(first_blade)}: 2),
          ...>   0
          ...> )
          new(scalar: 1)

      """
      def grade(%__MODULE__{data: d}, g) do
        %__MODULE__{data: grade(d, g)}
      end

      unquote_splicing(clauses)

      def grade(t, r) when is_tuple(t) do
        raise ArgumentError, "invalid grade #{r} for given multivector (#{inspect(t)})"
      end
    end
  end

  def grades_impl(dimension, bases) do
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

    first_blade = "e#{elem(bases, 0)}"

    quote do
      @doc """
      Returns the grades present in a multivector.

      The returned list contains every grade with at least one non-zero
      coefficient, ordered from lowest to highest.

      ## Examples

          iex> grades(
          ...>   new(scalar: 1)
          ...> )
          [0]

          iex> grades(
          ...>   new(#{unquote(first_blade)}: 2)
          ...> )
          [1]

          iex> grades(
          ...>   new(scalar: 1, #{unquote(first_blade)}: 2)
          ...> )
          [0, 1]

          iex> grades(
          ...>   new()
          ...> )
          []

      """
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

  def guard_impl(blade_indices) do
    conditions =
      for {grade, condition} <- grade_guard_conditions(blade_indices) do
        quote do
          unquote(grade) == grade and unquote(condition)
        end
      end

    guard_condition =
      Enum.reduce(conditions, fn a, b ->
        quote do
          unquote(a) or unquote(b)
        end
      end)

    quote do
      @doc """
      Checks whether a multivector contains components of the given grade only.

      A multivector is considered to have a grade if all non-zero components belong
      to that grade. The zero multivector is considered to have grade 0.

      The `is_grade(vector, grade)` guard can be used in function guards:

          def foo(mv) when is_grade(mv, 1) do
            mv
          end

      ## Examples

          iex> grade?(new(e1: 1), 1)
          true

          iex> grade?(new(scalar: 1, e1: 2), 2)
          false

          iex> grade?(new(scalar: 1), 0)
          true

          iex> grade?(new(), 0)
          true

      See `grade?/2`
      """
      defguard is_grade(mv, grade) when unquote(guard_condition)

      @doc """
      Checks whether a multivector contains components of the given grade only.

      A multivector is considered to have a grade if all non-zero components belong
      to that grade. The zero multivector is considered to have grade 0.

      ## Examples

          iex> grade?(new(e1: 1), 1)
          true

          iex> grade?(new(scalar: 1, e1: 2), 2)
          false

          iex> grade?(new(scalar: 1), 0)
          true

          iex> grade?(new(), 0)
          true

      See `is_grade/2`
      """
      def grade?(mv, g) when is_grade(mv, g), do: true
      def grade?(_mv, _g), do: false
    end
  end

  defp grade_guard_conditions(blade_indices) do
    grades =
      blade_indices
      |> Enum.group_by(fn {_name, mask} ->
        Galixir.Blade.grade(mask)
      end)

    Enum.map(grades, fn {grade, blades} ->
      condition =
        if grade == 0 do
          # Scalars and zero
          blade_indices
          |> Enum.reject(fn {_name, mask} ->
            Galixir.Blade.grade(mask) == 0
          end)
          |> Enum.map(fn {_name, index} ->
            quote do
              elem(mv.data, unquote(index)) == 0
            end
          end)
          |> Chain.and_chain()
        else
          present =
            blades
            |> Enum.map(fn {_name, index} ->
              quote do
                elem(mv.data, unquote(index)) != 0
              end
            end)
            |> Chain.or_chain()

          absent =
            blade_indices
            |> Enum.reject(fn {_name, mask} ->
              Galixir.Blade.grade(mask) == grade
            end)
            |> Enum.map(fn {_name, index} ->
              quote do
                elem(mv.data, unquote(index)) == 0
              end
            end)
            |> Chain.and_chain()

          quote do
            unquote(present) and unquote(absent)
          end
        end

      {grade, condition}
    end)
  end
end
