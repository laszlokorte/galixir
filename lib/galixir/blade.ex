defmodule Galixir.Blade do
  @moduledoc """
  Provides operations on basis blades using bitmask encoding.

  A basis blade is represented as an integer bitmask where each bit indicates
  whether a basis vector is present.

  For example, in a 3-dimensional algebra:

      e1  -> 001
      e2  -> 010
      e3  -> 100
      e12 -> 011
      e13 -> 101
      e123 -> 111

  This representation allows basis blade operations such as multiplication,
  grading, and dual computation to be performed efficiently using bitwise
  operations.

  Blade multiplication is determined by two factors:

    * the sign caused by reordering basis vectors into canonical order
    * the metric contribution from repeated basis vectors

  """

  @doc """
  Returns the grade of a basis blade.

  The grade is the number of basis vectors contained in the blade. It is
  calculated by counting the number of set bits in the blade mask.

  ## Examples

      iex> Galixir.Blade.grade(0b011)
      2

      iex> Galixir.Blade.grade(0b111)
      3

  """
  def grade(mask) do
    popcount(mask)
  end

  @doc """
  Multiplies two basis blades using the given metric signature.

  Returns a tuple containing:

    * the scalar coefficient (`1`, `-1`, or `0`)
    * the resulting blade mask

  The multiplication consists of:

    1. Reordering basis vectors into canonical order, producing a sign.
    2. Applying the metric for basis vectors appearing in both blades.
    3. Combining the remaining basis vectors using XOR.

  ## Examples

      iex> Galixir.Blade.multiply(0b001, 0b010, {1, 1, 1})
      {1, 3}

      iex> Galixir.Blade.multiply(0b001, 0b001, {1, 1, 1})
      {1, 0}

  ## Signature

  The signature defines the square of each basis vector:

      {1, -1, 0}

  represents:

      e1² = 1
      e2² = -1
      e3² = 0

  """
  def multiply(a, b, signature) do
    sign =
      swap_sign(a, b)

    metric =
      metric_factor(Bitwise.band(a, b), signature)

    {
      sign * metric,
      Bitwise.bxor(a, b)
    }
  end

  @doc """
  Calculates the sign required to reorder two blades into canonical order.

  When multiplying blades, basis vectors from the left blade must be moved
  before those from the right blade. Each swap changes the sign of the result.

  Returns:

    * `1`  when an even number of swaps is required
    * `-1` when an odd number of swaps is required

  """
  def swap_sign(a, b) do
    swaps =
      a
      |> bit_positions()
      |> Enum.reduce(0, fn i, acc ->
        lower_bits =
          Bitwise.band(b, Bitwise.bsl(1, i) - 1)

        acc + popcount(lower_bits)
      end)

    if rem(swaps, 2) == 0 do
      1
    else
      -1
    end
  end

  @doc """
  Calculates the sign contribution of dualizing a blade.

  The dual of a blade is computed relative to the pseudoscalar of the algebra.
  This function determines the sign introduced when moving the blade and its
  complement into canonical order.

  """
  def dual_sign(mask, dimension) do
    full = Bitwise.bsl(1, dimension) - 1
    complement = Bitwise.bxor(mask, full)

    swaps =
      bit_positions(mask)
      |> Enum.reduce(0, fn i, acc ->
        # Number of basis vectors in the complement
        # that must cross e_i.
        acc +
          popcount(
            Bitwise.band(
              complement,
              Bitwise.bsl(1, i) - 1
            )
          )
      end)

    if rem(swaps, 2) == 0, do: 1, else: -1
  end

  @doc """
  Returns the basis vector indices contained in a blade mask.

  Each set bit in the mask corresponds to a basis vector. Indices are zero-based
  and follow the ordering used by the algebra signature.

  ## Examples

        iex> Galixir.Blade.indices(0b001)
        [0]

        iex> Galixir.Blade.indices(0b101)
        [0, 2]

        iex> Galixir.Blade.indices(0b111)
        [0, 1, 2]

  """
  def indices(mask) do
    bit_positions(mask)
  end

  @doc """
  Returns a human-readable representation of a blade mask using the given basis
  identifiers.

  The `bases` tuple defines the labels corresponding to bit positions in the mask.

  ## Examples

      iex> Galixir.Blade.inspect(0b001, {1, 2, 3})
      "e1"

      iex> Galixir.Blade.inspect(0b101, {1, 2, 3})
      "e13"

      iex> Galixir.Blade.inspect(0b1000, {1, 2, 3, 0})
      "e0"

      iex> Galixir.Blade.inspect(0, {1, 2, 3})
      "1"

  """
  def inspect(mask, bases) do
    case indices(mask) do
      [] ->
        "1"

      positions ->
        positions
        |> Enum.map(&elem(bases, &1))
        |> Enum.map_join("", &to_string/1)
        |> then(&"e#{&1}")
    end
  end

  defp popcount(n, acc \\ 0)
  defp popcount(0, acc), do: acc
  defp popcount(n, acc), do: popcount(Bitwise.bsr(n, 1), acc + Bitwise.band(n, 1))

  defp metric_factor(common, signature) do
    common
    |> bit_positions()
    |> Enum.reduce(1, fn i, acc ->
      acc * elem(signature, i)
    end)
  end

  defp bit_positions(mask) do
    do_bit_positions(mask, 0, [])
  end

  defp do_bit_positions(0, _i, acc) do
    Enum.reverse(acc)
  end

  defp do_bit_positions(mask, i, acc) do
    acc =
      if Bitwise.band(mask, 1) == 1 do
        [i | acc]
      else
        acc
      end

    do_bit_positions(mask |> Bitwise.bsr(1), i + 1, acc)
  end
end
