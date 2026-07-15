defmodule Galixir.Generator.Utils do
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
