defmodule Galixir.Generator do
  def basis_names(bases) when is_list(bases) do
    dimensions = Enum.count(bases)
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
            |> Enum.map(fn {_, i} -> Enum.at(bases, i) end)
            |> Enum.join()

          "e" <> blade
        end

      quote do
        def basis_name(unquote(mask)), do: unquote(name)
      end
    end
  end

  def blade_indices(bases) when is_list(bases) do
    dimensions = Enum.count(bases)
    blade_count = Bitwise.bsl(1, dimensions)

    for mask <- 0..(blade_count - 1), into: %{} do
      {blade_atom(mask, bases), mask}
    end
  end

  def blade_aliases(bases) when is_list(bases) do
    dimensions = Enum.count(bases)
    blade_count = Bitwise.bsl(1, dimensions)

    0..(blade_count - 1)
    |> Enum.flat_map(fn mask ->
      indices = bits_to_indices(mask)
      canonical = blade_atom(mask, bases)

      Enum.map(permutations(indices), fn perm ->
        {
          blade_atom_from_indices(for p <- perm, do: Enum.at(bases, p)),
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
      for i <- 0..(Enum.count(bases) - 1),
          Bitwise.band(mask, Bitwise.bsl(1, i)) != 0 do
        Enum.at(bases, i)
      end
      |> Enum.join()

    String.to_atom("e" <> suffix)
  end
end
