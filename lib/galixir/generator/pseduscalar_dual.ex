defmodule Galixir.Generator.PseudoscalarDual do
  @moduledoc """
  Generates dual and undual operations for multivectors.
  """

  @behaviour Galixir.GeneratorBehaviour
  @impl Galixir.GeneratorBehaviour
  def generate_implementation(%Galixir.Meta{} = meta) do
    if Galixir.Meta.degenerate?(meta) do
      []
    else
      [dual_impl()]
    end
  end

  def dual_impl do
    quote do
      @doc """
      Returns the pseudoscalar dual of a multivector.

      The dual is computed by right-multiplying the multivector by the inverse
      of the algebra's pseudoscalar. For general mixed-grade multivectors,
      the geometric product may contain multiple grades.

      This operation is only defined for non-degenerate algebras, where
      the pseudoscalar is invertible.

      See `hodge_dual/1` and `hodge_undual/1` for the metric-independent Hodge dual.

      ## Examples

          iex> p = new(scalar: 2.0)
          iex> undual(dual(p)) == p
          true

          iex> p = new(scalar: 2.0)
          iex> dual(undual(p)) == p
          true

      """

      @doc group: :dual
      def dual(%__MODULE__{} = mv) do
        gp(mv, inverse!(pseudoscalar()))
      end

      @doc """
      Returns the inverse pseudoscalar dual of a multivector.

      This right-multiplies the multivector by the algebra's pseudoscalar
      and reverses the operation performed by `dual/1`.


      See `hodge_dual/1` and `hodge_undual/1` for the metric-independent Hodge dual.

      ## Examples

          iex> p = new(scalar: 3.0)
          iex> undual(dual(p)) == p
          true

          iex> p = new(scalar: 3.0)
          iex> dual(undual(p)) == p
          true

      """

      @doc group: :dual
      def undual(%__MODULE__{} = mv) do
        gp(mv, pseudoscalar())
      end
    end
  end
end
