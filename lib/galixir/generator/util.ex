defmodule Galixir.Generator.Utils do
  @moduledoc """
  Provides shared AST and documentation helpers for algebra generators.
  """

  def keyword_ast(key, value) do
    Macro.escape([{key, value}])
  end

  def generate_doc(description, examples \\ []) do
    examples =
      case examples do
        [] ->
          ""

        examples ->
          """

          ## Examples

          #{format_examples(examples)}
          """
      end

    quote do
      @doc unquote("""
           #{description}
           #{examples}
           """)
    end
  end

  def format_examples(examples) do
    Enum.map_join(examples, "\n\n", fn {input, output} ->
      format_iex(input, output)
    end)
  end

  def format_iex(ast, result) do
    code =
      ast
      |> Macro.to_string()
      |> String.split("\n")
      |> Enum.with_index()
      |> Enum.map_join("\n", fn
        {line, 0} -> "    iex> #{line}"
        {line, _i} -> "    ...> #{line}"
      end)

    """
    #{code}
        #{Macro.to_string(result)}
    """
  end

  def generate_unary_function(name, args, result, description, examples \\ []) do
    tuple_fun = :"#{name}_tuple"
    doc = generate_doc(description, examples)

    quote do
      unquote(doc)

      def unquote(name)(%__MODULE__{data: d}) do
        %__MODULE__{data: unquote(tuple_fun)(d)}
      end

      def unquote(tuple_fun)(unquote(tuple_ast(args))) do
        unquote(tuple_ast(result))
      end
    end
  end

  def generate_binary_function(name, args_a, args_b, result, description, examples \\ []) do
    tuple_fun = :"#{name}_tuple"

    doc = generate_doc(description, examples)

    quote do
      unquote(doc)

      def unquote(name)(%__MODULE__{data: a}, %__MODULE__{data: b}) do
        %__MODULE__{data: unquote(tuple_fun)(a, b)}
      end

      def unquote(tuple_fun)(
            unquote(tuple_ast(args_a)),
            unquote(tuple_ast(args_b))
          ) do
        unquote(tuple_ast(result))
      end
    end
  end

  def vars(prefix, size) do
    for i <- 0..(size - 1) do
      Macro.var(:"#{prefix}#{i}", nil)
    end
  end

  def blade_grade(mask) do
    mask
    |> Integer.digits(2)
    |> Enum.sum()
  end

  def reverse_sign(k) do
    if rem(div(k * (k - 1), 2), 2) == 0 do
      1
    else
      -1
    end
  end

  def sum([]) do
    quote do: 0
  end

  def sum(xs) do
    Enum.reduce(xs, fn x, acc ->
      quote do
        unquote(acc) + unquote(x)
      end
    end)
  end

  def tuple_ast(values) do
    values =
      Enum.map(values, fn
        nil -> quote do: _
        value -> value
      end)

    {:{}, [], values}
  end
end
