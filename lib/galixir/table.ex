defmodule Galixir.Table do
  @moduledoc """
  Provides utilities for generating geometric product lookup tables.

  The multiplication table contains the precomputed result of multiplying
  every pair of basis blades for a given metric.

  It is used during algebra generation to avoid recomputing the geometric
  product at runtime. Each entry stores the coefficient and resulting blade
  produced by multiplying two basis blades.

  The number of possible blades for an algebra of dimension `n` is:

      2ⁿ

  where each basis vector can either be present or absent in a blade.

  """

  alias Galixir.Blade

  @doc """
  Builds a geometric product multiplication table for a metric.

  The returned map contains entries only for products that have a non-zero
  coefficient.

  Each key is a pair of blade indices, and the value is the multiplication
  result:

      {
        {left_blade, right_blade},
        {coefficient, result_blade}
      }

  ## Examples

      iex> Galixir.Table.build({1, 1})
      %{
        {0, 0} => {1, 0},
        {1, 1} => {1, 0},
        {0, 1} => {1, 1},
        {0, 2} => {1, 2},
        {0, 3} => {1, 3},
        {1, 0} => {1, 1},
        {1, 2} => {1, 3},
        {1, 3} => {1, 2},
        {2, 0} => {1, 2},
        {2, 1} => {-1, 3},
        {2, 2} => {1, 0},
        {2, 3} => {-1, 1},
        {3, 0} => {1, 3},
        {3, 1} => {-1, 2},
        {3, 2} => {1, 1},
        {3, 3} => {-1, 0}
      }

  The metric determines the calculation of products:

    * `1`  gives `eᵢ² = 1`
    * `-1` gives `eᵢ² = -1`
    * `0`  gives `eᵢ² = 0`

  """
  def build(metric) do
    blades = blades(metric)

    for a <- blades,
        b <- blades,
        {coef, _} = result = Blade.multiply(a, b, metric),
        coef != 0,
        into: %{} do
      {{a, b}, result}
    end
  end

  @doc """
  Returns the range of blade indices for a given metric.

  A dimension `n` algebra has `2ⁿ` possible basis blades, including the scalar
  blade.

  ## Examples

      iex> Galixir.Table.blades({1, 1, 1})
      0..7

  """
  def blades(metric) do
    0..(blade_count(metric) - 1)
  end

  @doc """
  Returns the dimension of an algebra metric.

  ## Examples

      iex> Galixir.Table.dimension({1, 1, 1, 0})
      4

  """
  def dimension(metric) do
    tuple_size(metric)
  end

  @doc """
  Returns the total number of basis blades for a metric.

  The number of blades is `2ⁿ`, where `n` is the dimension of the algebra.

  ## Examples

      iex> Galixir.Table.blade_count({1, 1, 1})
      8

      iex> Galixir.Table.blade_count({})
      1

      iex> Galixir.Table.blade_count({1})
      2

      iex> Galixir.Table.blade_count({1, 0})
      4

  """
  def blade_count(metric) do
    1 |> Bitwise.bsl(dimension(metric))
  end
end
