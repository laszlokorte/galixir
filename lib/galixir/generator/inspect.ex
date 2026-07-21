defmodule Galixir.Generator.Inspect do
  def inspect_impl(bases) do
    first_blade = "e#{elem(bases, 0)}"

    quote do
      @doc """
      Formats a multivector using standard geometric algebra notation.

      Zero coefficients are omitted. Coefficients of `1` and `-1` are elided for
      non-scalar basis blades.

      ## Examples

          iex> inspect(#{inspect(__MODULE__)}.new())
          "0"

          iex> inspect(#{inspect(__MODULE__)}.new(scalar: 2))
          "2.0"

          iex> inspect(#{inspect(__MODULE__)}.new(#{unquote(first_blade)}: 1))
          "#{unquote(first_blade)}"

          iex> inspect(#{inspect(__MODULE__)}.new(scalar: 1, #{unquote(first_blade)}: 2))
          "1.0 + 2.0#{unquote(first_blade)}"
      """
      def to_string(v) do
        inspect(v)
      end

      defimpl Inspect, for: __MODULE__ do
        import Inspect.Algebra

        def inspect(value, _opts) do
          value.data
          |> Tuple.to_list()
          |> Enum.with_index()
          |> Enum.filter(fn {coef, _} -> coef != 0 end)
          |> format_terms(value)
        end

        defp format_terms([], _value), do: "0"

        defp format_terms([{coef, blade} | rest], value) do
          first =
            format_term(coef, blade, value, true)

          rest =
            rest
            |> Enum.map(&format_term(elem(&1, 0), elem(&1, 1), value, false))

          Enum.join([first | rest], " ")
        end

        defp format_term(coef, blade, value, first?) do
          name = value.__struct__.basis_name(blade)

          cond do
            coef == 1 and name != "" ->
              if first?, do: name, else: "+ #{name}"

            coef == -1 and name != "" ->
              "- #{name}"

            coef > 0 ->
              if first? do
                "#{coef}#{name}"
              else
                "+ #{coef}#{name}"
              end

            true ->
              "#{coef}#{name}"
          end
        end
      end
    end
  end
end
