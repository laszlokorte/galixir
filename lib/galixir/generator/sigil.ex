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
      """
      defmacro sigil_G({:<<>>, _, [string]}, []) do
        fields = parse_expression(string, [])

        quote do
          unquote(__MODULE__).new(unquote(fields))
        end
      end

      defp parse_expression(binary, acc, sign \\ 1)

      defp parse_expression(<<>>, acc, _sign) do
        Enum.reverse(acc)
      end

      defp parse_expression(binary, acc, sign) do
        binary = skip_spaces(binary)

        {sign, binary} =
          case binary do
            <<"+", rest::binary>> ->
              {sign, skip_spaces(rest)}

            <<"-", rest::binary>> ->
              {-sign, skip_spaces(rest)}

            _ ->
              {sign, binary}
          end

        {term, rest} = parse_term(binary)

        {blade, coef} = term
        term = {blade, sign * coef}

        case skip_spaces(rest) do
          <<"+", rest::binary>> ->
            parse_expression(rest, [term | acc], 1)

          <<"-", rest::binary>> ->
            parse_expression(rest, [term | acc], -1)

          "" ->
            Enum.reverse([term | acc])

          rest ->
            parse_expression(rest, [term | acc], 1)
        end
      end

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

      defp parse_blade(<<"e", rest::binary>>) do
        {symbols, rest} = take_basis_names(rest, [])

        if symbols == [] do
          raise ArgumentError, "expected basis after e, got '#{rest}'"
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

      defp take_blade(binary, acc) do
        case Enum.find(@basis_names, fn name ->
               String.starts_with?(binary, name)
             end) do
          nil ->
            {acc, binary}

          name ->
            {matched, rest} = String.split_at(binary, byte_size(name))
            take_blade(rest, <<acc::binary, matched::binary>>)
        end
      end

      defp take_digits(<<c, rest::binary>>) when c in ?0..?9 do
        take_digits(rest, <<c>>)
      end

      defp take_digits(rest), do: {"", rest}

      defp take_digits(<<c, rest::binary>>, acc) when c in ?0..?9 do
        take_digits(rest, <<acc::binary, c>>)
      end

      defp take_digits(rest, acc), do: {acc, rest}

      defp skip_spaces(<<" ", rest::binary>>), do: skip_spaces(rest)
      defp skip_spaces(binary), do: binary
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
