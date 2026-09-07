defmodule Galixir.Generator.Inspect do
  @moduledoc """
  Generates the string and `Inspect` representations of multivectors.
  """

  alias Galixir.GeneratorBehaviour

  @behaviour GeneratorBehaviour

  @impl GeneratorBehaviour
  def generate_implementation(%Galixir.Meta{
        bases: bases,
        module: module,
        blade_indices: blade_indices
      }) do
    [
      inspect_impl(bases, module, blade_indices)
    ]
  end

  def inspect_impl(bases, module, blade_indices) do
    first_blade = "e#{elem(bases, 0)}"

    quote do
      @doc """
      Formats this multivector as geometric algebra notation.

      This is the same representation used by `Inspect`.

      ## Examples

          iex> inspect(new())
          "~G[0.0]"

          iex> inspect(new(), custom_options: [all_blades: true])
          "#{unquote(blade_indices |> Enum.sort_by(fn {_, i} -> i end) |> Enum.map_join(" + ", fn
        {:scalar, _} -> "0.0"
        {b, _} -> "0.0#{b}"
      end) |> then(&"~G[#{&1}]"))}"

          iex> inspect(new(scalar: -2))
          "~G[-2.0]"

          iex> inspect(new(scalar: 2))
          "~G[2.0]"

          iex> inspect(new(scalar: -2))
          "~G[-2.0]"

          iex> inspect(new(#{unquote(first_blade)}: 1))
          "~G[1.0#{unquote(first_blade)}]"

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

          iex> inspect(~G[ε + εe1])
          "~G[ε + εe1]"
          iex> inspect(~G[-ε - εe1])
          "~G[-ε - εe1]"
      """

      @doc group: :formatting
      def format(value, opts) do
        format_document(value, opts)
      end

      defp format_document(value, %Inspect.Opts{custom_options: custom_opts} = opts) do
        eps = Keyword.get(custom_opts, :epsilon, @epsilon)
        skip_eps = Keyword.get(custom_opts, :skip_epsilon, false)
        all_blades = Keyword.get(custom_opts, :all_blades, false)

        hard_epsilon = if(all_blades, do: -1.0, else: if(skip_eps, do: eps, else: 0.0))

        value.data
        |> Tuple.to_list()
        |> Enum.with_index()
        |> Enum.filter(fn {coef, _blade} ->
          abs(coef) > hard_epsilon
        end)
        |> format_terms(value, opts)
      end

      defp format_terms([], _value, opts) do
        Inspect.Algebra.concat([
          Inspect.Algebra.string("~G["),
          Inspect.Algebra.to_doc(0.0, opts),
          Inspect.Algebra.string("]")
        ])
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

      defp format_term(
             coef,
             blade,
             value,
             %Inspect.Opts{custom_options: custom_opts} = opts,
             first?
           ) do
        import Inspect.Algebra

        name = value.__struct__.basis_name(blade)
        short_ones = Keyword.get(custom_opts, :short_ones, false)
        eps = Keyword.get(custom_opts, :epsilon, @epsilon)

        doc = concat([collapse_abs_epsilon(coef, eps, opts), string(name)])

        cond do
          short_ones and coef == 1.0 and name != "" ->
            signed_term(name, first?, "+")

          short_ones and coef == -1.0 and name != "" ->
            signed_term(name, first?, "-")

          coef >= 0.0 ->
            signed_term(
              doc,
              first?,
              "+"
            )

          true ->
            signed_term(
              doc,
              first?,
              "-"
            )
        end
      end

      defp collapse_abs_epsilon(value, eps, opts) do
        import Inspect.Algebra

        abs(value)
        |> case do
          abs when abs > 0.0 and abs <= eps -> "ε"
          abs -> to_doc(abs, opts)
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
