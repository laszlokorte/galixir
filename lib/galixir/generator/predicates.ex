defmodule Galixir.Generator.Predicates do
  alias Galixir.Chain
  import Galixir.Generator.Utils, only: [tuple_ast: 1]
  alias Galixir.GeneratorBehaviour
  @behaviour GeneratorBehaviour
  @impl GeneratorBehaviour
  def generate_implementation(%Galixir.Meta{
        bases: bases,
        dimensions: dimensions,
        blade_indices: bi
      }) do
    [
      scalar_check_impl(dimensions, bases),
      zero_check_impl(dimensions, bases),
      blade_check_impl(bases),
      blade_guard_impl(bi)
    ]
  end

  def scalar_check_impl(dimension, bases) do
    blade_count = Bitwise.bsl(1, dimension)

    a =
      for i <- 0..(blade_count - 1) do
        if i == 0 do
          nil
        else
          Macro.var(:"a#{i}", nil)
        end
      end

    first_basis = "e#{elem(bases, 0)}"

    quote do
      @doc """
      Checks whether a multivector contains only a scalar component.

      Components with an absolute value smaller than `eps` are considered
      zero.

      ## Examples

          iex> scalar?(new(scalar: 3))
          true

          iex> scalar?(new(#{unquote(first_basis)}: 3))
          false

          iex> scalar?(new())
          true
      """
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

  def zero_check_impl(dimension, bases) do
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

    guard_checks =
      for i <- 0..(blade_count - 1) do
        quote do
          elem(mv.data, unquote(i)) == 0
        end
      end

    guard_condition = guard_checks |> Chain.and_chain()

    first_basis = "e#{elem(bases, 0)}"

    quote do
      @doc """
      Checks whether all coefficients of a multivector are zero.

      ## Examples

          iex> zero?(new())
          true

          iex> zero?(new(#{unquote(first_basis)}: 1))
          false
      """
      def zero?(%__MODULE__{data: d}) do
        zero?(d)
      end

      def zero?(unquote(tuple_ast(a))) do
        unquote(condition)
      end

      @doc """
      A guard that matches multi vectors that are all zero.

      Can be used in function guards:

          def foo(x) when is_zero(x), do: x
      """
      defguard is_zero(mv) when unquote(guard_condition)
    end
  end

  def blade_check_impl(bases) do
    doc =
      if tuple_size(bases) > 1 do
        first_basis = "e#{elem(bases, 0)}"
        second_basis = "e#{elem(bases, 1)}"
        bibasis = "e#{elem(bases, 0)}#{elem(bases, 1)}"

        quote do
          @doc """
          Checks whether a multivector is a blade.

          A blade is a multivector containing components from at most one grade.

          Scalars are considered blades.

          ## Examples

              iex> blade?(new(#{unquote(first_basis)}: 2))
              true

              iex> blade?(new(#{unquote(bibasis)}: 1))
              true

              iex> blade?(new(#{unquote(first_basis)}: 1, #{unquote(second_basis)}: 1))
              true

              iex> blade?(new(scalar: 2, #{unquote(first_basis)}: 2))
              false

              iex> blade?(new(#{unquote(second_basis)}: 2, #{unquote(bibasis)}: 2))
              false
          """
        end
      else
        first_basis = "e#{elem(bases, 0)}"

        quote do
          @doc """
          Checks whether a multivector is a blade.

          A blade is a multivector containing components from at most one grade.

          Scalars are considered blades.

          ## Examples

              iex> blade?(new(#{unquote(first_basis)}: 2))
              true

              iex> blade?(new(scalar: 2))
              true

              iex> blade?(new(scalar: 2, #{unquote(first_basis)}: 1))
              false
          """
        end
      end

    quote do
      unquote(doc)

      def blade?(%__MODULE__{} = a) do
        Enum.count(grades(a)) <= 1
      end
    end
  end

  def blade_guard_impl(blade_indices) do
    grades =
      blade_indices
      |> Enum.group_by(fn {_name, index} ->
        Galixir.Blade.grade(index)
      end)

    grade_checks =
      grades
      |> Map.values()
      |> Enum.map(fn blades ->
        blades
        |> Enum.map(fn {_name, index} ->
          quote do
            elem(mv.data, unquote(index)) != 0.0
          end
        end)
        |> Enum.reduce(fn a, b ->
          quote do
            unquote(a) or unquote(b)
          end
        end)
      end)

    guard_condition =
      grade_checks
      |> Enum.with_index()
      |> Enum.flat_map(fn {a, i} ->
        grade_checks
        |> Enum.drop(i + 1)
        |> Enum.map(fn b ->
          quote do
            not (unquote(a) and unquote(b))
          end
        end)
      end)
      |> Enum.reduce(fn a, b ->
        quote do
          unquote(a) and unquote(b)
        end
      end)

    quote do
      defguard is_blade(mv) when unquote(guard_condition)
    end
  end
end
