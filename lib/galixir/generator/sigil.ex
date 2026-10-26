defmodule Galixir.Generator.Sigil do
  @moduledoc """
  Generates the `~G` sigil for constructing multivectors from strings.
  """

  alias Galixir.GeneratorBehaviour

  @behaviour GeneratorBehaviour

  @impl GeneratorBehaviour
  def generate_implementation(%Galixir.Meta{bases: bases}) do
    [
      sigil_impl(bases)
    ]
  end

  def sigil_impl(bases) do
    quote do
      @doc """
      Creates a multivector from a string representation.

      The `~G` sigil provides a convenient syntax for constructing multivectors
      using basis blades and coefficients.

      Examples:

      #{unquote(sigil_examples(bases))}

      The parsed expression is converted into the same representation accepted by
      `new/1`, so blade ordering and signs are handled by the algebra implementation.
      Use the algebra's `:bases` identifiers in blade names. The parser accepts
      decimal and integer coefficients, `ε` for `epsilon/0`, and spaces; it
      does not parse scientific notation or arbitrary Elixir expressions.
      """

      @doc group: :parse
      defmacro sigil_G({:<<>>, _, [string]}, []) do
        fields = parse_expression(string, [])

        quote do
          unquote(__MODULE__).new(unquote(fields))
        end
      end

      @doc """
      Parses a string representation into a multivector.

      The string may contain scalar coefficients and basis blades combined
      using `+` and `-` operators. A blade without a coefficient has
      coefficient one; `ε` denotes `epsilon/0`. Empty expressions, missing
      operators, trailing operators, and unsupported tokens raise `ArgumentError`.

      Examples:

          iex> parse("1 + e1")
          new(scalar: 1, e1: 1)

          iex> parse("foo")
          ** (ArgumentError) expected number ...
      """

      @doc group: :parse
      def parse(string) do
        string
        |> parse_expression([])
        |> new()
      end

      unquote(expression_parser_impl())
      unquote(term_parser_impl())
      unquote(blade_parser_impl())
    end
  end

  defp expression_parser_impl do
    quote do
      defp parse_expression(binary, acc) do
        {sign, rest} = parse_sign(skip_spaces(binary))
        parse_signed_term(rest, acc, sign)
      end

      defp parse_sign(<<"+", rest::binary>>), do: {1, skip_spaces(rest)}
      defp parse_sign(<<"-", rest::binary>>), do: {-1, skip_spaces(rest)}
      defp parse_sign(rest), do: {1, rest}

      defp parse_signed_term(binary, acc, sign) do
        {{blade, coef}, rest} = parse_term(binary)
        parse_operator(skip_spaces(rest), [{blade, sign * coef} | acc])
      end

      defp parse_operator("", acc), do: Enum.reverse(acc)

      defp parse_operator(<<"+", rest::binary>>, acc) do
        parse_signed_term(skip_spaces(rest), acc, 1)
      end

      defp parse_operator(<<"-", rest::binary>>, acc) do
        parse_signed_term(skip_spaces(rest), acc, -1)
      end

      defp parse_operator(rest, _acc) do
        raise ArgumentError, "expected + or - in #{inspect(rest)}"
      end

      defp skip_spaces(<<" ", rest::binary>>), do: skip_spaces(rest)
      defp skip_spaces(binary), do: binary
    end
  end

  defp term_parser_impl do
    quote do
      defp parse_term(binary) do
        case binary do
          <<"e", _::binary>> ->
            {blade, rest} = parse_blade(binary)
            {{blade, 1}, rest}

          _ ->
            {coef, rest} = parse_number(binary)

            case rest do
              <<"*", rest::binary>> ->
                {blade, rest} = parse_blade(skip_spaces(rest))
                {{blade, coef}, rest}

              <<"e", _::binary>> ->
                {blade, rest} = parse_blade(rest)
                {{blade, coef}, rest}

              rest ->
                {{:scalar, coef}, rest}
            end
        end
      end

      defp parse_number(<<"ε", rest::binary>>) do
        {@epsilon, rest}
      end

      defp parse_number(binary) do
        {digits, rest} = take_number(binary, "")

        if digits == "" do
          raise ArgumentError, "expected number in #{inspect(binary)}"
        end

        {parse_numeric(digits), rest}
      end

      defp take_number(<<c, rest::binary>>, acc)
           when c in ?0..?9 or c == ?. do
        take_number(rest, <<acc::binary, c>>)
      end

      defp take_number(rest, acc), do: {acc, rest}

      defp parse_numeric(number) do
        if String.contains?(number, ".") do
          String.to_float(number)
        else
          String.to_integer(number)
        end
      end
    end
  end

  defp blade_parser_impl do
    quote do
      defp parse_blade(<<"e", rest::binary>> = all) do
        {symbols, rest} = take_basis_names(rest, [])

        if symbols == [] do
          raise ArgumentError, "expected basis after e, got '#{all}'"
        end

        blade =
          ["e" | symbols]
          |> Enum.join()
          |> String.to_existing_atom()

        {blade, rest}
      end

      defp take_basis_names(binary, acc) do
        case Enum.find(@basis_names, fn name ->
               String.starts_with?(binary, name)
             end) do
          nil ->
            {Enum.reverse(acc), binary}

          name ->
            rest = binary_part(binary, byte_size(name), byte_size(binary) - byte_size(name))
            take_basis_names(rest, [name | acc])
        end
      end
    end
  end

  defp sigil_examples(bases) do
    case Tuple.to_list(bases) do
      [a, b | _] ->
        """
            iex> ~G"e#{a} + e#{b}"
            new(e#{a}: 1, e#{b}: 1)

            iex> ~G"2e#{a} - 0.5e#{a}#{b}"
            new(e#{a}: 2, e#{a}#{b}: -0.5)

            iex> ~G"e#{a}#{b}"
            new(e#{a}#{b}: 1)

            iex> ~G"3"
            new(scalar: 3)

            iex> ~G[ε + εe#{a}]
            new(scalar: epsilon(), e#{a}: epsilon())

            iex> ~G[-ε - εe#{a}]
            new(scalar: -epsilon(), e#{a}: -epsilon())
        """

      [a | _] ->
        """
            iex> ~G"e#{a}"
            new(e#{a}: 1)

            iex> ~G"3"
            new(scalar: 3)
        """

      [] ->
        """
          iex> ~G"3 + e5"
          new(scalar: 3)
        """
    end
  end
end
