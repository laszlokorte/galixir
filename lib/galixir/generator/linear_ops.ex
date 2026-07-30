defmodule Galixir.Generator.LinearOps do
  @moduledoc """
  Generates component-wise addition, subtraction, and scaling operations.
  """

  import Galixir.Generator.Utils, only: [vars: 2, tuple_ast: 1]
  alias Galixir.Table
  alias Galixir.GeneratorBehaviour
  @behaviour GeneratorBehaviour
  @impl GeneratorBehaviour
  def generate_implementation(%Galixir.Meta{metric: metric}) do
    blade_count = Table.blade_count(metric)

    [
      add(blade_count),
      sub(blade_count),
      scale(blade_count)
    ]
  end

  defp add(blade_count) do
    a = vars(:a, blade_count)
    b = vars(:b, blade_count)

    result =
      for i <- 0..(blade_count - 1) do
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

            iex> a = new(scalar: 2)
            iex> b = new(scalar: 3)
            iex> add(a, b)
            new(scalar: 5)
        """
      end
    )
  end

  defp sub(blade_count) do
    a = vars(:a, blade_count)
    b = vars(:b, blade_count)

    result =
      for i <- 0..(blade_count - 1) do
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

            iex> a = new(scalar: 5)
            iex> b = new(scalar: 2)
            iex> sub(a, b)
            new(scalar: 3)
        """
      end
    )
  end

  defp scale(blade_count) do
    a = vars(:a, blade_count)
    s = Macro.var(:s, nil)

    result =
      for i <- 0..(blade_count - 1) do
        quote do
          (unquote(s) * unquote(Enum.at(a, i))) |> then(&if(&1 == 0.0, do: 0.0, else: &1))
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
