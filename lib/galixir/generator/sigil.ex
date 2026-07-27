defmodule Galixir.Generator.Sigil do
  alias Galixir.GeneratorBehaviour

  @behaviour GeneratorBehaviour

  @impl GeneratorBehaviour
  def generate_implementation(%Galixir.Meta{}) do
    [
      sigil_impl()
    ]
  end

  def sigil_impl() do
    quote do
      defmacro sigil_G({:<<>>, _, [string]}, []) do
        fields = parse_expression(string, [])

        quote do
          unquote(__MODULE__).new(unquote(fields))
        end
      end

      defp parse_expression(<<>>, acc), do: Enum.reverse(acc)

      defp parse_expression(binary, acc) do
        {term, rest} = parse_term(skip_spaces(binary))

        rest =
          case skip_spaces(rest) do
            <<"+", rest::binary>> -> rest
            rest -> rest
          end

        parse_expression(rest, [term | acc])
      end

      defp parse_term(binary) do
        {sign, binary} =
          case binary do
            <<"-", rest::binary>> -> {-1, rest}
            <<"+", rest::binary>> -> {1, rest}
            _ -> {1, binary}
          end

        {coef, rest} = parse_number(binary)

        case rest do
          <<"*", rest::binary>> ->
            {blade, rest} = parse_blade(rest)
            {{blade, sign * coef}, rest}

          <<"e", _::binary>> ->
            {blade, rest} = parse_blade(rest)
            {{blade, sign * coef}, rest}

          _ ->
            {{:scalar, sign * coef}, rest}
        end
      end

      defp parse_number(binary) do
        parse_number(binary, 0)
      end

      defp parse_number(<<c, rest::binary>>, acc) when c in ?0..?9 do
        parse_number(rest, acc * 10 + c - ?0)
      end

      defp parse_number(rest, acc) do
        {acc, rest}
      end

      defp parse_blade(<<"e", rest::binary>>) do
        {digits, rest} = take_digits(rest)
        {String.to_atom("e" <> digits), rest}
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
end
