defmodule Galixir.Generator.Canonical do
  @moduledoc """
  Generates helpers for determining canonical properties of multivectors.

  The generated functions operate on the internal coefficient storage
  representation of a multivector.

  These helpers are used by higher-level operations that need to determine
  properties such as the dominant coefficient or the overall sign of a
  multivector.

  Since multivectors may contain multiple grades and components, these
  functions avoid making assumptions about the geometric meaning of a
  multivector and operate purely on its coefficients.
  """
  import Galixir.Generator.Utils, only: [vars: 2, tuple_ast: 1]

  @behaviour Galixir.GeneratorBehaviour
  @impl Galixir.GeneratorBehaviour
  def generate_implementation(%Galixir.Meta{dimensions: d, bases: b}) do
    [
      max_abs_component_impl(d, b),
      canonical_sign_impl(d, b)
    ]
  end

  @doc """
  Generates a `max_abs_component/1` function.

  The generated function returns the largest absolute coefficient contained
  in a multivector.

  This is used by `canonicalize/1` to scale a homogeneous multivector
  so its largest absolute coefficient is one.

  ## Examples

  For a multivector:

      `3.0 + 2.0e1 - 5.0e12`

  the maximum absolute component is:

      5.0

  """
  def max_abs_component_impl(dimension, bases) do
    blade_count = Bitwise.bsl(1, dimension)

    first_blade = elem(bases, 0)

    blade = :"e#{first_blade}"

    a = vars(:a, blade_count)

    values =
      for i <- 0..(blade_count - 1) do
        quote do
          abs(unquote(Enum.at(a, i)))
        end
      end

    quote do
      @doc """
      Returns the maximum absolute coefficient of a multivector.

      Accepts a multivector struct. The internal tuple helper is private.

      ## Example

          iex> max_abs_component(new(#{unquote(blade)}: 2, scalar: 5))
          5.0

          iex> max_abs_component(new(#{unquote(blade)}: 5, scalar: 2))
          5.0
      """
      @doc group: :norm
      def max_abs_component(%__MODULE__{data: d}) do
        max_abs_component_tuple(d)
      end

      defp max_abs_component_tuple(unquote(tuple_ast(a))) do
        Enum.max([
          unquote_splicing(values)
        ])
      end
    end
  end

  @doc """
  Generates a `canonical_sign/1` function.

  The generated function returns the sign of the first non-zero coefficient
  in blade-bitmask storage order: `1` for positive, `-1` for negative, and
  `0` when all coefficients are zero.

  The function is used by `canonicalize/1` to choose a deterministic sign
  for a homogeneous multivector.

  ## Examples

      canonical_sign(3e1 + 2e2)
      # => 1

      canonical_sign(-3e1 + 2e2)
      # => -1

  """
  def canonical_sign_impl(dimension, bases) do
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

    first_blade = elem(bases, 0)

    blade = :"e#{first_blade}"

    quote do
      @doc """
      Returns the canonical sign of a multivector.

      The canonical sign is determined by the first non-zero coefficient in
      storage order.

      Returns:

        * `1` if the first non-zero coefficient is positive
        * `-1` if the first non-zero coefficient is negative
        * `0` if all coefficients are zero

      ## Examples

          iex> canonical_sign(new(#{unquote(blade)}: 2))
          1

          iex> canonical_sign(new(#{unquote(blade)}: -2))
          -1

          iex> canonical_sign(new())
          0

      """

      @doc group: :norm
      def canonical_sign(%__MODULE__{data: d}) do
        canonical_sign_tuple(d)
      end

      defp canonical_sign_tuple(unquote(tuple_ast(a))) do
        result =
          [
            unquote_splicing(clauses)
          ]
          |> Enum.find(&(&1 != nil))

        result || 0
      end
    end
  end
end
