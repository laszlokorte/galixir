defmodule Galixir.Generator.Cofficients do
  @moduledoc """
  Generates coefficient access functions for multivectors.

  Multivectors store their coefficients in a fixed-size tuple indexed by the
  blade bitmask. These helpers provide access to individual blade coefficients
  while handling blade aliases and canonical ordering.
  """
  def coefficient_impl(module, bases) do
    first_blade = elem(bases, 0)

    blade = :"e#{first_blade}"

    quote do
      @doc """
      Returns the coefficient of a basis blade.

      The requested blade can be given in canonical form or as any registered
      blade alias. Aliases are automatically converted to the canonical blade
      and the appropriate sign is applied.

         ## Examples

        iex> #{unquote(module)}.coefficient(
        ...>   #{unquote(module)}.new(#{unquote(blade)}: 3),
        ...>   :#{unquote(blade)}
        ...> )
        3

      """
      def coefficient(%__MODULE__{data: data}, blade) do
        {canonical, sign} =
          Map.get(@blade_aliases, blade, {blade, 1})

        sign * elem(data, Map.fetch!(@blade_indices, canonical))
      end

      @doc """
      Returns the scalar coefficient of a multivector.

      This is equivalent to retrieving the coefficient of the scalar blade.

      ## Examples

          iex> #{unquote(module)}.scalar_part(#{unquote(module)}.new(scalar: 5, #{unquote(blade)}: 2))
          5

      """
      def scalar_part(%__MODULE__{data: data}) do
        elem(data, 0)
      end
    end
  end
end
