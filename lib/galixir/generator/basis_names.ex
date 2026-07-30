defmodule Galixir.Generator.BasisNames do
  @moduledoc """
  Generates functions that map basis-blade masks to their canonical names.
  """

  @behaviour Galixir.GeneratorBehaviour
  @impl Galixir.GeneratorBehaviour
  def generate_implementation(%Galixir.Meta{bases: b}) do
    [
      basis_names_impl(b)
    ]
  end

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
  def basis_names_impl(bases) when is_tuple(bases) do
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
            |> Enum.map_join(fn {_, i} -> elem(bases, i) end)

          "e" <> blade
        end

      quote do
        def basis_name(unquote(mask)), do: unquote(name)
      end
    end
  end
end
