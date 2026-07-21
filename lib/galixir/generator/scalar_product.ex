defmodule Galixir.Generator.ScalarProduct do
  import Galixir.Generator.Utils, only: [tuple_ast: 1, sum: 1]

  def scalar_product_impl(dimension, signature, bases) do
    blade_count = Bitwise.bsl(1, dimension)

    raw_terms =
      for a <- 0..(blade_count - 1),
          b <- 0..(blade_count - 1) do
        {coef, result} =
          Galixir.Blade.multiply(
            a,
            b,
            signature
          )

        if coef != 0 and result == 0 do
          {a, b, coef}
        else
          nil
        end
      end
      |> Enum.reject(&is_nil/1)

    used_lhs =
      raw_terms
      |> Enum.map(fn {a, _, _} -> a end)
      |> MapSet.new()

    used_rhs =
      raw_terms
      |> Enum.map(fn {_, b, _} -> b end)
      |> MapSet.new()

    lhs =
      for a <- 0..(blade_count - 1) do
        if MapSet.member?(used_lhs, a) do
          Macro.var(:"lhs#{a}", nil)
        else
          nil
        end
      end

    rhs =
      for b <- 0..(blade_count - 1) do
        if MapSet.member?(used_rhs, b) do
          Macro.var(:"rhs#{b}", nil)
        else
          nil
        end
      end

    terms =
      for {a, b, coef} <- raw_terms do
        ca = Enum.at(lhs, a)
        cb = Enum.at(rhs, b)

        case coef do
          1 ->
            quote do
              unquote(ca) * unquote(cb)
            end

          -1 ->
            quote do
              -(unquote(ca) * unquote(cb))
            end
        end
      end

    first_sig = elem(signature, 0)

    first_basis = "e#{elem(bases, 0)}"

    quote do
      @doc """
      Computes the scalar product of two multivectors.

      The scalar product is the grade-0 component of the geometric product:

          <a b>₀

      The result depends on the metric signature of the algebra. In particular,
      basis vectors with negative or null squares affect the result.

      ## Examples

          iex> #{inspect(__MODULE__)}.scalar_product(
          ...>   #{inspect(__MODULE__)}.new(#{unquote(first_basis)}: 2),
          ...>   #{inspect(__MODULE__)}.new(#{unquote(first_basis)}: 3)
          ...> )
          #{unquote(6.0 * first_sig)}

      """
      def scalar_product(%__MODULE__{data: a}, %__MODULE__{data: b}) do
        scalar_product(a, b)
      end

      def scalar_product(unquote(tuple_ast(lhs)), unquote(tuple_ast(rhs))) do
        unquote(sum(terms))
      end
    end
  end
end
