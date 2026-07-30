defmodule Galixir.Generator.Reverse do
  @moduledoc """
  Generates reversion operations for multivectors.
  """

  import Galixir.Generator.Utils, only: [vars: 2, tuple_ast: 1, blade_grade: 1, reverse_sign: 1]
  alias Galixir.Table
  alias Galixir.GeneratorBehaviour
  @behaviour GeneratorBehaviour
  @impl GeneratorBehaviour
  def generate_implementation(%Galixir.Meta{metric: metric, bases: bases}) do
    blade_count = Table.blade_count(metric)

    [
      reverse_impl(blade_count, bases)
    ]
  end

  def reverse_impl(blade_count, bases) do
    a = vars(:a, blade_count)

    result =
      for mask <- 0..(blade_count - 1) do
        sign = reverse_sign(blade_grade(mask))

        if sign == -1 do
          quote do
            unquote(Enum.at(a, mask)) |> Galixir.negate_coefficient()
          end
        else
          Enum.at(a, mask)
        end
      end

    doc =
      if tuple_size(bases) > 1 do
        first_basis = "e#{elem(bases, 0)}"
        bibasis = "e#{elem(bases, 0)}#{elem(bases, 1)}"

        quote do
          @doc """
          Applies the reverse operation to a multivector.

          Reverse (also called reversion) changes the sign of basis blades according
          to their grade:

              grade 0:  +
              grade 1:  +
              grade 2:  -
              grade 3:  -
              grade 4:  +
              ...

          For a blade with grade `r`, the sign is:

              (-1)^(r(r-1)/2)

          ## Examples

              iex> reverse(new(#{unquote(first_basis)}: 2))
              new(#{unquote(first_basis)}: 2)

              iex> reverse(new(#{unquote(bibasis)}: 2))
              new(#{unquote(bibasis)}: -2)

              iex> reverse(new(scalar: 3))
              new(scalar: 3)

          """
        end
      else
        first_basis = "e#{elem(bases, 0)}"

        quote do
          @doc """
          Applies the reverse operation to a multivector.

          Reverse (also called reversion) changes the sign of basis blades according
          to their grade:

              grade 0:  +
              grade 1:  +
              grade 2:  -
              grade 3:  -
              grade 4:  +
              ...

          For a blade with grade `r`, the sign is:

              (-1)^(r(r-1)/2)

          ## Examples

              iex> reverse(new(#{unquote(first_basis)}: 2))
              new(#{unquote(first_basis)}: 2)

              iex> reverse(new(scalar: 3))
              new(scalar: 3)
          """
        end
      end

    quote do
      unquote(doc)

      def reverse(%__MODULE__{data: d}) do
        %__MODULE__{data: reverse_tuple(d)}
      end

      def reverse_tuple(unquote(tuple_ast(a))) do
        unquote(tuple_ast(result))
      end
    end
  end
end
