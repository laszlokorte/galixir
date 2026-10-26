defmodule Galixir.Generator.HodgeDual do
  @moduledoc """
  Generates `hodge_dual/1` and `hodge_undual/1` operations for multivectors.

  Unlike the pseudoscalar dual, the Hodge dual is defined independently
  of the metric and therefore also works for degenerate algebras.
  """

  alias Galixir.Generator.Utils
  import Utils, only: [vars: 2, sum: 1]

  @behaviour Galixir.GeneratorBehaviour
  @impl Galixir.GeneratorBehaviour
  def generate_implementation(%Galixir.Meta{bases: b, dimensions: d} = meta) do
    [
      hodge_dual_impl(d, b, Galixir.Meta.degenerate?(meta))
    ]
  end

  def hodge_dual_impl(dimension, bases, degenerate?) do
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

            if sign == -1 do
              quote do
                unquote(value) |> Galixir.negate_coefficient()
              end
            else
              value
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
            quote(do: -unquote(Enum.at(a, complement)) |> then(&if(&1 == 0.0, do: 0.0, else: &1)))
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

    funs = [
      Utils.generate_unary_function(
        :hodge_dual,
        a,
        result,
        """
        Computes the Hodge dual of a multivector.

        The Hodge dual maps each basis blade to its complementary blade with
        the appropriate orientation sign. The complementary blade is determined
        by the pseudoscalar of the algebra.

        The operation is linear and is applied independently to each basis
        blade and its coefficient.

        Unlike the pseudoscalar dual, the Hodge dual does not require the
        pseudoscalar to be invertible and is therefore also defined for
        degenerate algebras.

        The operations are inverses:

            hodge_undual(hodge_dual(a)) == a
            hodge_dual(hodge_undual(a)) == a

        See `hodge_undual/1` for the inverse operation.
        #{if(degenerate?, do: "", else: "See `dual/1` for the pseudoscalar-based dual.")}
        """,
        [
          {
            quote do
              hodge_dual(new(unquote(Utils.keyword_ast(first_blade, 1))))
              |> inspect
            end,
            quote do
              new(unquote(Utils.keyword_ast(dual_blade, dual_value))) |> inspect
            end
          }
        ],
        :dual
      ),
      Utils.generate_unary_function(
        :hodge_undual,
        a,
        undual_result,
        """
        Computes the inverse Hodge dual of a multivector.

        `hodge_undual/1` reverses the blade-complement operation performed by
        `hodge_dual/1`, mapping each basis blade back to its complementary blade
        with the appropriate orientation sign.

        The operation is linear and is applied independently to each basis blade
        and its coefficient.

        Unlike the pseudoscalar dual, the Hodge dual and its inverse are defined
        for degenerate algebras as well.

        The operations are inverses:

            hodge_undual(hodge_dual(a)) == a
            hodge_dual(hodge_undual(a)) == a


        See `hodge_dual/1` for the inverse operation.
        #{if(degenerate?, do: "", else: "See `dual/1` for the pseudoscalar-based dual.")}
        """,
        [
          {
            quote do
              hodge_undual(hodge_dual(new(unquote(Utils.keyword_ast(first_blade, 2)))))
            end,
            quote do
              new(unquote(Utils.keyword_ast(first_blade, 2)))
            end
          }
        ],
        :dual
      )
    ]

    quote do
      (unquote_splicing(funs))
    end
  end
end
