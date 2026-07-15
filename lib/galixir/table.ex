defmodule Galixir.Table do
  alias Galixir.Blade

  @doc """
  Builds the multiplication table for a metric signature.

  Example:

      build([1, 1, 1])

  returns a map containing all blade products.
  """
  def build(signature) do
    blades = blades(signature)

    for a <- blades,
        b <- blades,
        {coef, _} = result = Blade.multiply(a, b, signature),
        coef != 0,
        into: %{} do
      {{a, b}, result}
    end
  end

  def blades(signature) do
    0..(blade_count(signature) - 1)
  end

  def dimension(signature) do
    length(signature)
  end

  def blade_count(signature) do
    1 |> Bitwise.bsl(dimension(signature))
  end
end
