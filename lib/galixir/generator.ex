defmodule Galixir.Generator do
  def basis_names(size) do
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
            |> Enum.map(fn {_, i} -> Integer.to_string(i + 1) end)
            |> Enum.join()

          "e" <> blade
        end

      quote do
        def basis_name(unquote(mask)), do: unquote(name)
      end
    end
  end

  def blade_indices(dimensions) do
    blade_count = Bitwise.bsl(1, dimensions)

    for mask <- 0..(blade_count - 1), into: %{} do
      {blade_atom(mask, dimensions), mask}
    end
  end

  defp blade_atom(0, _size), do: :scalar

  defp blade_atom(mask, size) do
    suffix =
      for i <- 0..(size - 1),
          Bitwise.band(mask, Bitwise.bsl(1, i)) != 0 do
        Integer.to_string(i + 1)
      end
      |> Enum.join()

    String.to_atom("e" <> suffix)
  end
end
