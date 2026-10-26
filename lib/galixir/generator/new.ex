defmodule Galixir.Generator.New do
  @moduledoc """
  Generates constructors for multivectors.
  """

  alias Galixir.GeneratorBehaviour
  @behaviour GeneratorBehaviour
  @impl GeneratorBehaviour

  def generate_implementation(%Galixir.Meta{metric: metric}) do
    blade_count = Galixir.Table.blade_count(metric)

    [
      new_impl(blade_count)
    ]
  end

  def new_impl(blade_count) do
    quote do
      @doc """
      Constructs a multivector from blade coefficients or a coefficient tuple.

      A keyword list (or list of `{blade, coefficient}` pairs) accepts canonical
      blade names and reordered aliases; repeated terms are added together.
      Missing coefficients default to zero. A tuple must contain exactly
      #{unquote(blade_count)} coefficients in blade-bitmask order and is used
      as given, without conversion or validation of its elements.

      ## Examples

          iex> new()
          new()

          iex> new(scalar: 2)
          new(scalar: 2)
      """
      @doc group: :construction
      def new(basis \\ [])

      def new(data) when is_tuple(data) and tuple_size(data) == unquote(blade_count) do
        %__MODULE__{data: data}
      end

      def new(fields) when is_list(fields) do
        coeffs = :erlang.make_tuple(unquote(blade_count), 0.0)

        coeffs =
          Enum.reduce(fields, coeffs, fn {blade, coef}, acc ->
            {canonical, sign} =
              Map.get(@blade_aliases, blade, {blade, 1})

            index =
              Map.fetch!(@blade_indices, canonical)

            put_elem(acc, index, 1.0 * sign * coef + elem(acc, index))
          end)

        %__MODULE__{data: coeffs}
      end
    end
  end
end
