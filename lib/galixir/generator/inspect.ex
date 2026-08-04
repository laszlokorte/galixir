defmodule Galixir.Generator.Inspect do
  @moduledoc """
  Generates the string and `Inspect` representations of multivectors.
  """

  alias Galixir.GeneratorBehaviour

  @behaviour GeneratorBehaviour

  @impl GeneratorBehaviour
  def generate_implementation(%Galixir.Meta{bases: bases, module: module}) do
    [
      inspect_impl(bases, module)
    ]
  end

  def inspect_impl(bases, module) do
    first_blade = "e#{elem(bases, 0)}"

    quote do
      @doc """
      Formats this multivector as geometric algebra notation.

      This is the same representation used by `Inspect`.

      ## Examples

          iex> inspect(new())
          "~G[0]"

          iex> inspect(new(scalar: -2))
          "~G[-2.0]"

          iex> inspect(new(scalar: 2))
          "~G[2.0]"

          iex> inspect(new(scalar: -2))
          "~G[-2.0]"

          iex> inspect(new(#{unquote(first_blade)}: 1))
          "~G[#{unquote(first_blade)}]"

          iex> inspect(new(scalar: 1, #{unquote(first_blade)}: 2))
          "~G[1.0 + 2.0#{unquote(first_blade)}]"

          iex> inspect(new(scalar: 1, #{unquote(first_blade)}: -2))
          "~G[1.0 - 2.0#{unquote(first_blade)}]"

          iex> inspect(new(scalar: -1, #{unquote(first_blade)}: -2))
          "~G[-1.0 - 2.0#{unquote(first_blade)}]"

          iex> inspect(new(scalar: -1, #{unquote(first_blade)}: 2))
          "~G[-1.0 + 2.0#{unquote(first_blade)}]"

          iex> inspect(new(#{unquote(first_blade)}: 2))
          "~G[2.0#{unquote(first_blade)}]"

          iex> inspect(new(#{unquote(first_blade)}: -2))
          "~G[-2.0#{unquote(first_blade)}]"
      """
      def format(value, opts) do
        format_document(value, opts)
      end

      defp format_document(value, opts = %Inspect.Opts{custom_options: custom_opts}) do
        value.data
        |> Tuple.to_list()
        |> Enum.with_index()
        |> Enum.filter(fn {coef, _blade} ->
          abs(coef) > Keyword.get(custom_opts, :epsilon, 1.0e-10)
        end)
        |> format_terms(value, opts)
      end

      defp format_terms([], _value, _opts) do
        Inspect.Algebra.string("~G[0]")
      end

      defp format_terms(terms, value, opts) do
        Inspect.Algebra.concat([
          Inspect.Algebra.string("~G["),
          format_term_list(terms, value, opts),
          Inspect.Algebra.string("]")
        ])
      end

      defp format_term_list([{coef, blade} | rest], value, opts) do
        Inspect.Algebra.concat([
          format_term(coef, blade, value, opts, true),
          rest
          |> Enum.map(fn {coef, blade} ->
            format_term(coef, blade, value, opts, false)
          end)
          |> Inspect.Algebra.concat()
        ])
      end

      defp format_term(coef, blade, value, opts, first?) do
        import Inspect.Algebra

        name = value.__struct__.basis_name(blade)

        cond do
          coef == 1.0 and name != "" ->
            signed_term(name, first?, "+")

          coef == -1.0 and name != "" ->
            signed_term(name, first?, "-")

          coef > 0.0 ->
            signed_term(
              concat([to_doc(coef, opts), string(name)]),
              first?,
              "+"
            )

          true ->
            signed_term(
              concat([to_doc(abs(coef), opts), string(name)]),
              first?,
              "-"
            )
        end
      end

      defp signed_term(term, true, "+") do
        term
      end

      defp signed_term(term, true, "-") do
        Inspect.Algebra.concat([
          Inspect.Algebra.string("-"),
          term
        ])
      end

      defp signed_term(term, false, "+") do
        Inspect.Algebra.concat([
          Inspect.Algebra.string(" + "),
          term
        ])
      end

      defp signed_term(term, false, "-") do
        Inspect.Algebra.concat([
          Inspect.Algebra.string(" - "),
          term
        ])
      end

      defimpl Inspect, for: unquote(module) do
        def inspect(value, opts) do
          value
          |> unquote(module).format(opts)
        end
      end
    end
  end
end
