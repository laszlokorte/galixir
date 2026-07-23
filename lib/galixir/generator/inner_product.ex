defmodule Galixir.Generator.InnerProduct do
  import Galixir.Generator.Utils,
    only: [vars: 2, sum: 1, blade_grade: 1, tuple_ast: 1]

  def inner_product_impl(signature, bases, mode \\ :inner) do
    dimension = tuple_size(signature)
    blade_count = Bitwise.bsl(1, dimension)

    lhs = vars(:lhs, blade_count)
    rhs = vars(:rhs, blade_count)

    grade_matches? =
      case mode do
        :inner ->
          fn ga, gb, gr ->
            gr == abs(ga - gb)
          end

        :left ->
          fn ga, gb, gr ->
            ga <= gb and gr == gb - ga
          end

        :right ->
          fn ga, gb, gr ->
            ga >= gb and gr == ga - gb
          end

        _ ->
          raise ArgumentError,
                "unknown contraction mode: #{inspect(mode)}"
      end

    terms =
      for a <- 0..(blade_count - 1),
          b <- 0..(blade_count - 1) do
        {coef, result} =
          Galixir.Blade.multiply(a, b, signature)

        ga = blade_grade(a)
        gb = blade_grade(b)
        gr = blade_grade(result)

        if coef != 0 and grade_matches?.(ga, gb, gr) do
          ca = Enum.at(lhs, a)
          cb = Enum.at(rhs, b)

          term =
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

          {result, term, a, b}
        else
          nil
        end
      end
      |> Enum.reject(&is_nil/1)

    used_lhs =
      terms
      |> Enum.map(fn {_, _, a, _} -> a end)
      |> MapSet.new()

    used_rhs =
      terms
      |> Enum.map(fn {_, _, _, b} -> b end)
      |> MapSet.new()

    lhs =
      Enum.with_index(lhs)
      |> Enum.map(fn {v, i} ->
        if MapSet.member?(used_lhs, i), do: v, else: nil
      end)

    rhs =
      Enum.with_index(rhs)
      |> Enum.map(fn {v, i} ->
        if MapSet.member?(used_rhs, i), do: v, else: nil
      end)

    result =
      for index <- 0..(blade_count - 1) do
        terms
        |> Enum.filter(fn {r, _, _, _} -> r == index end)
        |> Enum.map(fn {_, t, _, _} -> t end)
        |> sum()
      end

    {function_name, operation_name} =
      case mode do
        :inner ->
          {:inner, "inner product"}

        :left ->
          {:left_contraction, "left contraction"}

        :right ->
          {:right_contraction, "right contraction"}
      end

    first_blade = "e#{elem(bases, 0)}"

    quote do
      @doc """
      Computes the #{unquote(operation_name)} of two multivectors.

      The operation is generated from the geometric product and retains only
      terms satisfying the grade selection rule.

      ## Example

          iex> #{inspect(__MODULE__)}.#{unquote(function_name)}(
          ...>   #{inspect(__MODULE__)}.new(#{unquote(first_blade)}: 2),
          ...>   #{inspect(__MODULE__)}.new(#{unquote(first_blade)}: 3)
          ...> )

      """
      def unquote(function_name)(
            %__MODULE__{data: a},
            %__MODULE__{data: b}
          ) do
        %__MODULE__{
          data: unquote(function_name)(a, b)
        }
      end

      def unquote(function_name)(
            unquote(tuple_ast(lhs)),
            unquote(tuple_ast(rhs))
          ) do
        unquote(tuple_ast(result))
      end
    end
  end
end
