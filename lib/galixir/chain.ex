defmodule Galixir.Chain do
  @moduledoc """
  Builds quoted boolean expressions from lists of quoted conditions.
  """

  def or_chain([]), do: quote(do: false)

  def or_chain([first | rest]) do
    Enum.reduce(rest, first, fn expr, acc ->
      quote do
        unquote(acc) or unquote(expr)
      end
    end)
  end

  def and_chain([]), do: quote(do: true)

  def and_chain([first | rest]) do
    Enum.reduce(rest, first, fn expr, acc ->
      quote do
        unquote(acc) and unquote(expr)
      end
    end)
  end
end
