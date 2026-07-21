defmodule Galixir.Generator do
  @moduledoc """
  Provides compile-time helpers for generating geometric algebra modules.

  The generator translates the internal bitmask representation of basis blades
  into Elixir functions and lookup tables.

  Basis blades are represented internally as integers where each bit indicates
  the presence of a basis vector. This module generates the mapping between
  those masks and their human-readable representations.

  For example, with:

      bases: {1, 2, 3}

  the generator creates mappings such as:

      0      -> :scalar
      1      -> :e1
      2      -> :e2
      3      -> :e12
      7      -> :e123

  The generated data is used by `Galixir.GeometricAlgebra` when building a
  concrete algebra implementation.
  """

  @doc """
  Generates functions mapping blade masks to their names.

  The generated functions have the form:

      basis_name(mask)

  and return the canonical name of a basis blade.

  The scalar blade is represented by an empty name.

  ## Examples

  Given:

      bases: {1, 2, 3}

  this generates:

      basis_name(0)  # => ""
      basis_name(1)  # => "e1"
      basis_name(3)  # => "e12"
      basis_name(7)  # => "e123"

  """
  def basis_names(bases) when is_tuple(bases) do
    dimensions = tuple_size(bases)
    size = Bitwise.bsl(1, dimensions)

    for mask <- 0..(size - 1) do
      name =
        if mask == 0 do
          ""
        else
          blade =
            mask
            |> Integer.digits(2)
            |> Enum.reverse()
            |> Enum.with_index()
            |> Enum.filter(fn {bit, _} -> bit == 1 end)
            |> Enum.map(fn {_, i} -> elem(bases, i) end)
            |> Enum.join()

          "e" <> blade
        end

      quote do
        def basis_name(unquote(mask)), do: unquote(name)
      end
    end
  end

  @doc """
  Generates a lookup table from blade names to storage indices.

  The generated index corresponds to the bitmask representation of the blade
  and is used as the position of the blade coefficient in the multivector
  storage.

  For example, for a three-dimensional algebra:

      :scalar -> 0
      :e1     -> 1
      :e2     -> 2
      :e12    -> 3
      :e3     -> 4
      :e23    -> 6
      :e123   -> 7

  The index is a bitmask, where each bit represents the presence of a basis
  vector.
  """
  def blade_indices(bases) when is_tuple(bases) do
    dimensions = tuple_size(bases)
    blade_count = Bitwise.bsl(1, dimensions)

    for mask <- 0..(blade_count - 1), into: %{} do
      {blade_atom(mask, bases), mask}
    end
  end

  @doc """
  Generates aliases for all permutations of basis blade names.

  Basis blades have a canonical ordering, but the same blade can be written
  using different permutations. This function creates a lookup table that maps
  non-canonical forms to their canonical representation and the sign introduced
  by reordering.

  For example:

      e21 = -e12

  produces an alias mapping equivalent to:

      :e21 => {:e12, -1}

  """

  def blade_aliases(bases) when is_tuple(bases) do
    dimensions = tuple_size(bases)
    blade_count = Bitwise.bsl(1, dimensions)

    0..(blade_count - 1)
    |> Enum.flat_map(fn mask ->
      indices = bits_to_indices(mask)
      canonical = blade_atom(mask, bases)

      Enum.map(permutations(indices), fn perm ->
        {
          blade_atom_from_indices(for p <- perm, do: elem(bases, p)),
          {canonical, permutation_sign(perm)}
        }
      end)
    end)
    |> Map.new()
  end

  defp permutations([]), do: [[]]

  defp permutations(list) do
    for x <- list,
        rest <- permutations(List.delete(list, x)) do
      [x | rest]
    end
  end

  defp blade_atom_from_indices([]), do: :scalar

  defp blade_atom_from_indices(indices) do
    :"e#{Enum.join(indices)}"
  end

  defp permutation_sign(list) do
    inversions =
      for {x, i} <- Enum.with_index(list),
          y <- Enum.drop(list, i + 1),
          x > y,
          reduce: 0 do
        acc -> acc + 1
      end

    if rem(inversions, 2) == 0, do: 1, else: -1
  end

  defp bits_to_indices(mask) do
    for i <- 0..63,
        Bitwise.band(mask, Bitwise.bsl(1, i)) != 0 do
      i
    end
  end

  defp blade_atom(0, _bases), do: :scalar

  defp blade_atom(mask, bases) do
    suffix =
      for i <- 0..(tuple_size(bases) - 1),
          Bitwise.band(mask, Bitwise.bsl(1, i)) != 0 do
        elem(bases, i)
      end
      |> Enum.join()

    String.to_atom("e" <> suffix)
  end
end
