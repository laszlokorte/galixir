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

    function(
      :add,
      a,
      b,
      result,
      quote do
        """
        Adds two multivectors component-wise.

        ## Examples

            iex> a = #{inspect(__MODULE__)}.new(scalar: 2)
            iex> b = #{inspect(__MODULE__)}.new(scalar: 3)
            iex> #{inspect(__MODULE__)}.add(a, b)
            #{inspect(__MODULE__)}.new(scalar: 5)
        """
      end
    )
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

    function(
      :sub,
      a,
      b,
      result,
      quote do
        """
        Subtracts two multivectors component-wise.

        ## Examples

            iex> a = #{inspect(__MODULE__)}.new(scalar: 5)
            iex> b = #{inspect(__MODULE__)}.new(scalar: 2)
            iex> #{inspect(__MODULE__)}.sub(a, b)
            #{inspect(__MODULE__)}.new(scalar: 3)
        """
      end
    )
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
      def scale(unquote(s), %__MODULE__{data: d}) when is_number(unquote(s)) do
        %__MODULE__{data: scale(unquote(s), d)}
      end

      def scale(unquote(s), unquote(tuple_ast(a))) when is_number(unquote(s)) do
        unquote(tuple_ast(result))
      end

      def scale(%__MODULE__{data: d}, unquote(s)) when is_number(unquote(s)) do
        %__MODULE__{data: scale(d, unquote(s))}
      end

      def scale(unquote(tuple_ast(a)), unquote(s)) when is_number(unquote(s)) do
        unquote(tuple_ast(result))
      end
    end
  end

  defp function(name, a, b, result, doc) do
    [
      quote do
        @doc unquote(doc)
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
