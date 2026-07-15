defmodule Galixir.Generator.LinearOps do
  import Galixir.Generator.Utils, only: [vars: 2, tuple_ast: 1]

  def linear_ops_impl(size) do
    [
      add(size),
      sub(size),
      scale(size)
    ]
  end

  defp add(size) do
    a = vars(:a, size)
    b = vars(:b, size)

    result =
      for i <- 0..(size - 1) do
        quote do
          unquote(Enum.at(a, i)) + unquote(Enum.at(b, i))
        end
      end

    function(:add, a, b, result)
  end

  defp sub(size) do
    a = vars(:a, size)
    b = vars(:b, size)

    result =
      for i <- 0..(size - 1) do
        quote do
          unquote(Enum.at(a, i)) - unquote(Enum.at(b, i))
        end
      end

    function(:sub, a, b, result)
  end

  defp scale(size) do
    a = vars(:a, size)
    s = Macro.var(:s, nil)

    result =
      for i <- 0..(size - 1) do
        quote do
          unquote(s) * unquote(Enum.at(a, i))
        end
      end

    quote do
      def scale(unquote(s), %__MODULE__{data: d}) do
        %__MODULE__{data: scale(unquote(s), d)}
      end

      def scale(unquote(s), unquote(tuple_ast(a))) do
        unquote(tuple_ast(result))
      end
    end
  end

  defp function(name, a, b, result) do
    [
      quote do
        def unquote(name)(
              %__MODULE__{data: a},
              %__MODULE__{data: b}
            ) do
          %__MODULE__{data: unquote(name)(a, b)}
        end
      end,
      quote do
        def unquote(name)(
              unquote(tuple_ast(a)),
              unquote(tuple_ast(b))
            ) do
          unquote(tuple_ast(result))
        end
      end
    ]
  end
end
