defmodule Galixir.Generator.Predicates do
  alias Galixir.Chain
  import Galixir.Generator.Utils, only: [tuple_ast: 1]

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

          iex> #{inspect(__MODULE__)}.scalar?(#{inspect(__MODULE__)}.new(scalar: 3))
          true

          iex> #{inspect(__MODULE__)}.scalar?(#{inspect(__MODULE__)}.new(#{unquote(first_basis)}: 3))
          false

          iex> #{inspect(__MODULE__)}.scalar?(#{inspect(__MODULE__)}.new())
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

    first_basis = "e#{elem(bases, 0)}"

    quote do
      @doc """
      Checks whether all coefficients of a multivector are zero.

      ## Examples

          iex> #{inspect(__MODULE__)}.zero?(#{inspect(__MODULE__)}.new())
          true

          iex> #{inspect(__MODULE__)}.zero?(#{inspect(__MODULE__)}.new(#{unquote(first_basis)}: 1))
          false
      """
      def zero?(%__MODULE__{data: d}) do
        zero?(d)
      end

      def zero?(unquote(tuple_ast(a))) do
        unquote(condition)
      end
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

              iex> #{inspect(__MODULE__)}.blade?(#{inspect(__MODULE__)}.new(#{unquote(first_basis)}: 2))
              true

              iex> #{inspect(__MODULE__)}.blade?(#{inspect(__MODULE__)}.new(#{unquote(bibasis)}: 1))
              true

              iex> #{inspect(__MODULE__)}.blade?(#{inspect(__MODULE__)}.new(#{unquote(first_basis)}: 1, #{unquote(second_basis)}: 1))
              true

              iex> #{inspect(__MODULE__)}.blade?(#{inspect(__MODULE__)}.new(scalar: 2, #{unquote(first_basis)}: 2))
              false

              iex> #{inspect(__MODULE__)}.blade?(#{inspect(__MODULE__)}.new(#{unquote(second_basis)}: 2, #{unquote(bibasis)}: 2))
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

              iex> #{inspect(__MODULE__)}.blade?(#{inspect(__MODULE__)}.new(#{unquote(first_basis)}: 2))
              true

              iex> #{inspect(__MODULE__)}.blade?(#{inspect(__MODULE__)}.new(scalar: 2))
              true

              iex> #{inspect(__MODULE__)}.blade?(#{inspect(__MODULE__)}.new(scalar: 2, #{unquote(first_basis)}: 1))
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
end
