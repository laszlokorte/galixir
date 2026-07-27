defmodule Galixir.Generator.Dual do
  alias Galixir.Generator.Utils
  import Utils, only: [vars: 2, sum: 1]

  @behaviour Galixir.GeneratorBehaviour
  @impl Galixir.GeneratorBehaviour
  def generate_implementation(%Galixir.Meta{module: m, bases: b, dimensions: d}) do
    [
      dual_impl(m, d, b)
    ]
  end

  def dual_impl(module, dimension, bases) do
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

    [
      Utils.generate_unary_function(
        :dual,
        a,
        result,
        """
        Computes the dual of a multivector.

        The dual maps each basis blade to its complementary blade with the
        appropriate orientation sign. The complement is determined by the full
        pseudoscalar of the algebra.

        The operation is linear and applies independently to every coefficient.
        """,
        [
          {
            quote do
              unquote(module).dual(
                unquote(module).new(unquote(Utils.keyword_ast(first_blade, 1)))
              )
              |> inspect
            end,
            quote do
              unquote(module).new(unquote(Utils.keyword_ast(dual_blade, dual_value))) |> inspect
            end
          }
        ]
      ),
      Utils.generate_unary_function(
        :undual,
        a,
        undual_result,
        """
        Computes the inverse dual operation.

        `undual/1` reverses the blade complement operation performed by
        `dual/1`.

        For non-degenerate Euclidean algebras this corresponds to applying the
        dual operation twice with the appropriate pseudoscalar factor. In
        degenerate algebras the result depends on the implemented dual
        convention.
        """,
        [
          {
            quote do
              unquote(module).undual(
                unquote(module).dual(
                  unquote(module).new(unquote(Utils.keyword_ast(first_blade, 2)))
                )
              )
            end,
            quote do
              unquote(module).new(unquote(Utils.keyword_ast(first_blade, 2)))
            end
          }
        ]
      )
    ]
  end
end
