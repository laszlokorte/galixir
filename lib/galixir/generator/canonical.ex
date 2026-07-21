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

  @doc """
  Generates a `max_abs_component/1` function.

  The generated function returns the largest absolute coefficient contained
  in a multivector.

  This is commonly used when selecting a numerically stable scale factor or
  determining whether a multivector has a significant component.

  ## Examples

  For a multivector:

      3.0 + 2.0e1 - 5.0e12

  the maximum absolute component is:

      5.0

  """
  def max_abs_component_impl(dimension, module, bases) do
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

      Accepts either a multivector struct or the internal coefficient tuple.

      ## Example

          iex> #{unquote(module)}.max_abs_component(#{unquote(module)}.new(#{unquote(blade)}: 2, scalar: 5))
          5.0

          iex> #{unquote(module)}.max_abs_component(#{unquote(module)}.new(#{unquote(blade)}: 5, scalar: 2))
          5.0
      """
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

  @doc """
  Generates a `canonical_sign/1` function.

  The generated function returns the sign of the first non-zero coefficient
  in storage order.

  It returns:

    * `1`  if the first non-zero coefficient is positive
    * `-1` if the first non-zero coefficient is negative
    * `1`  for a completely zero multivector

  The function is used to choose a deterministic sign representation for
  objects that are equivalent up to a scalar sign.

  ## Examples

      canonical_sign(3e1 + 2e2)
      # => 1

      canonical_sign(-3e1 + 2e2)
      # => -1

  """
  def canonical_sign_impl(dimension, module, bases) do
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

          iex> #{unquote(module)}.canonical_sign(#{unquote(module)}.new(#{unquote(blade)}: 2))
          1

          iex> #{unquote(module)}.canonical_sign(#{unquote(module)}.new(#{unquote(blade)}: -2))
          -1

          iex> #{unquote(module)}.canonical_sign(#{unquote(module)}.new())
          0

      """
      def canonical_sign(%__MODULE__{data: d}) do
        canonical_sign(d)
      end

      def canonical_sign(unquote(tuple_ast(a))) do
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
