defmodule Galixir.Generator.Dual do
  import Galixir.Generator.Utils, only: [vars: 2, tuple_ast: 1, sum: 1]

  def dual_impl(dimension, bases) do
    blade_count = Bitwise.bsl(1, dimension)
    full_mask = blade_count - 1

    a = vars(:a, blade_count)

    result =
      for out_mask <- 0..(blade_count - 1) do
        terms =
          for mask <- 0..(blade_count - 1),
              Bitwise.bxor(mask, full_mask) == out_mask do
            sign = Galixir.Blade.dual_sign(mask, dimension)

            value = Enum.at(a, mask)

            if sign == 1 do
              value
            else
              quote do
                -unquote(value)
              end
            end
          end

        sum(terms)
      end

    undual_result = List.duplicate(nil, blade_count)

    undual_result =
      Enum.reduce(0..(blade_count - 1), undual_result, fn mask, acc ->
        complement = Bitwise.bxor(mask, full_mask)
        sign = Galixir.Blade.dual_sign(mask, dimension)

        value =
          if sign == 1 do
            Enum.at(a, complement)
          else
            quote(do: -unquote(Enum.at(a, complement)))
          end

        List.replace_at(acc, mask, value)
      end)

    first_blade_mask = 1
    dual_mask = Bitwise.bxor(first_blade_mask, full_mask)
    dual_sign = Galixir.Blade.dual_sign(first_blade_mask, dimension)

    first_blade = Galixir.Generator.blade_atom(first_blade_mask, bases)
    dual_blade = Galixir.Generator.blade_atom(dual_mask, bases)

    dual_value =
      if dual_sign == 1 do
        1.0
      else
        -1.0
      end

    quote do
      @doc """
      Computes the dual of a multivector.

      The dual maps each basis blade to its complementary blade with the
      appropriate orientation sign. The complement is determined by the full
      pseudoscalar of the algebra.

      The operation is linear and applies independently to every coefficient.

      ## Examples

        iex> #{inspect(__MODULE__)}.dual(#{inspect(__MODULE__)}.new(#{unquote(first_blade)}: 1)) |> inspect
        #{inspect(__MODULE__)}.new(#{unquote(dual_blade)}: #{unquote(dual_value)}) |> inspect

      """
      def dual(%__MODULE__{data: d}) do
        %__MODULE__{data: dual(d)}
      end

      def dual(unquote(tuple_ast(a))) do
        unquote(tuple_ast(result))
      end

      @doc """
      Computes the inverse dual operation.

      `undual/1` reverses the blade complement operation performed by `dual/1`.

      For non-degenerate Euclidean algebras this corresponds to applying the
      dual operation twice with the appropriate pseudoscalar factor. In
      degenerate algebras the result depends on the implemented dual convention.

      ## Examples

          iex> #{inspect(__MODULE__)}.undual(#{inspect(__MODULE__)}.dual(#{inspect(__MODULE__)}.new(#{unquote(first_blade)}: 2)))
          #{inspect(__MODULE__)}.new(#{unquote(first_blade)}: 2)

      """
      def undual(%__MODULE__{data: d}) do
        %__MODULE__{data: undual(d)}
      end

      def undual(unquote(tuple_ast(a))) do
        unquote(tuple_ast(undual_result))
      end
    end
  end
end
