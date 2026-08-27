defmodule Galixir.Meta do
  @moduledoc """
  Stores the compile-time metadata used to generate a geometric algebra module.
  """

  @type t :: %__MODULE__{}

  defstruct [
    :module,
    :dimensions,
    :metric,
    :bases,
    :table,
    :blade_indices,
    :blade_aliases,
    :epsilon
  ]

  @doc """
  Returns whether the algebra has a degenerate metric.

  A metric is degenerate when at least one basis vector has a zero
  metric value.

  ## Examples

      iex> degenerate?(%Galixir.Meta{metric:  {1,1,0,1}})
      true

      iex> degenerate?(%Galixir.Meta{metric:  {1,1,1,1}})
      false
  """
  def degenerate?(%__MODULE__{metric: metric}) do
    metric |> Tuple.to_list() |> Enum.any?(&(&1 == 0))
  end

  def pseudoscalar_name(%__MODULE__{bases: bases}) do
    bases
    |> Tuple.to_list()
    |> Enum.join()
    |> then(&"e#{&1}")
    |> String.to_atom()
  end
end
