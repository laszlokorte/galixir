defmodule Galixir.Blade do
  @moduledoc """
  Basis blade operations using bitmask encoding.
  """

  @doc """
  Returns the grade of a blade.


  """
  def grade(mask) do
    popcount(mask)
  end

  @doc """
  Returns the sign and resulting blade of multiplying two blades.

  The signature is a list where each element is the square of a basis vector:

      [1, -1, 0] == e1²=1, e2²=-1, e3²=0
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

  # Count swaps needed to move all basis vectors of a
  # before those of b into canonical order.
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

  defp popcount(n, acc \\ 0)
  defp popcount(0, acc), do: acc
  defp popcount(n, acc), do: popcount(Bitwise.bsr(n, 1), acc + Bitwise.band(n, 1))

  defp metric_factor(common, signature) do
    common
    |> bit_positions()
    |> Enum.reduce(1, fn i, acc ->
      acc * Enum.at(signature, i)
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
