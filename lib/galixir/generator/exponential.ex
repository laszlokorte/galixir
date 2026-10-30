defmodule Galixir.Generator.Exponential do
  @moduledoc """
  Generates scaled-Taylor exponential and bounded near-identity logarithm operations.

  Complex1, Dual1, and Hyper1 retain their existing specialized elementary
  functions because their logarithm contracts cover domains beyond this local
  real Mercator-series implementation.
  """

  @behaviour Galixir.GeneratorBehaviour
  @impl Galixir.GeneratorBehaviour
  def generate_implementation(%Galixir.Meta{generic_exp: exp}) do
    if exp, do: [implementation()], else: []
  end

  defp implementation do
    quote do
      @doc """
      Computes the geometric-algebra exponential of a finite multivector using a
      scaled Taylor series and repeated squaring. The Taylor series uses at most
      256 terms after scaling the coefficient L2 norm to at most `0.5`; each term
      is `gp(previous_term, value) / k`. The summation stops when the next term's
      L2 norm is at most `1.0e-15` times the larger of one and the sum's L2 norm.

      Raises `ArgumentError` if the input or result has non-finite coefficients,
      or if the Taylor series does not converge within its term limit. The
      algebra's metric-dependent `norm/1` is not used for convergence control.

      ## Examples

          iex> exp(new())
          new(scalar: 1.0)

          iex> exp(new(scalar: 1))
          new(scalar: 2.7182818284590438)

          iex> exp(new(e12: 1)) |> coefficient(:e12)
          0.8414709848078965
      """
      @doc group: :exponential
      def exp(%__MODULE__{} = value) do
        unless exp_finite?(value) do
          raise ArgumentError, "cannot exponentiate a multivector with non-finite coefficients"
        end

        size = exp_l2_norm(value)
        squarings = if size == 0.0, do: 0, else: max(0, ceil(:math.log2(size) + 1))
        scaled = scale(:math.pow(0.5, squarings), value)
        result = exp_series(scaled, one(), one(), 1)
        result = exp_square(result, squarings)

        unless exp_finite?(result) do
          raise ArgumentError, "multivector exponential produced non-finite coefficients"
        end

        result
      end

      defp exp_series(_value, _sum, _term, 257) do
        raise ArgumentError, "multivector exponential Taylor series did not converge"
      end

      defp exp_series(value, sum, term, index) do
        next_term = scale(1.0 / index, gp(term, value))
        next_sum = add(sum, next_term)

        unless exp_finite?(next_term) and exp_finite?(next_sum) do
          raise ArgumentError,
                "multivector exponential Taylor series produced non-finite coefficients"
        end

        if exp_l2_norm(next_term) <= 1.0e-15 * max(1.0, exp_l2_norm(next_sum)) do
          next_sum
        else
          exp_series(value, next_sum, next_term, index + 1)
        end
      end

      defp exp_square(value, 0), do: value

      defp exp_square(value, count) do
        result = gp(value, value)

        unless exp_finite?(result) do
          raise ArgumentError, "multivector exponential produced non-finite coefficients"
        end

        exp_square(result, count - 1)
      end

      defp exp_finite?(%__MODULE__{data: data}) do
        Enum.all?(Tuple.to_list(data), &exp_coefficient_finite?/1)
      end

      defp exp_coefficient_finite?(value) when is_float(value) do
        value * 0.0 == 0.0
      end

      defp exp_coefficient_finite?(value) when is_integer(value) do
        _ = value * 1.0
        true
      rescue
        ArithmeticError -> false
      end

      defp exp_coefficient_finite?(_value), do: false

      defp exp_l2_norm(%__MODULE__{data: data}) do
        coefficients = Tuple.to_list(data)
        maximum = Enum.reduce(coefficients, 0.0, fn value, acc -> max(abs(value), acc) end)

        if maximum == 0.0 do
          0.0
        else
          maximum *
            :math.sqrt(
              Enum.reduce(coefficients, 0.0, fn value, acc ->
                normalized = value / maximum
                acc + normalized * normalized
              end)
            )
        end
      end

      @doc """
      Computes the real logarithm by the Mercator series `log(1 + u) =
      u - u²/2 + u³/3 - ...`, where `u = value - 1`.

      This intentionally supports only the conservative near-identity domain
      where the coefficient L1 norm of `u` is strictly less than one. In that
      domain the coefficient L1 norm is submultiplicative for Galixir's diagonal
      metrics, so the series converges. This is a principal local branch, not a
      general real multivector logarithm. Values outside the domain—including
      negative scalars and most singular values—return
      `{:error, :outside_convergence_domain}`. Non-finite coefficients return
      `{:error, :non_finite}`; failure to meet the relative `1.0e-15` term
      tolerance within 4096 terms returns `{:error, :no_convergence}`.

      The tolerance compares the term's coefficient L1 norm to `1.0e-15` times
      the larger of one and the sum's coefficient L1 norm. A successful result
      is `{:ok, logarithm}`. For example, this recovers small real scalar and
      nilpotent logarithms; it does not promise to find every real logarithm.

      ## Examples

          iex> log(one())
          {:ok, new()}

          iex> log(new(scalar: 1.5))
          {:ok, new(scalar: 0.40546510810816444)}

          iex> log(new(scalar: -1))
          {:error, :outside_convergence_domain}
      """
      @doc group: :exponential
      def log(%__MODULE__{} = value) do
        if exp_finite?(value) do
          delta = sub(value, one())
          distance = log_l1_norm(delta)

          if distance >= 1.0 do
            {:error, :outside_convergence_domain}
          else
            log_series(delta, gp(delta, delta), delta, 2)
          end
        else
          {:error, :non_finite}
        end
      end

      defp log_series(_value, _power, _sum, 4097), do: {:error, :no_convergence}

      defp log_series(value, power, sum, index) do
        sign = if rem(index, 2) == 0, do: -1.0, else: 1.0
        term = scale(sign / index, power)
        next_sum = add(sum, term)

        cond do
          not exp_finite?(term) or not exp_finite?(next_sum) ->
            {:error, :non_finite}

          log_l1_norm(term) <= 1.0e-15 * max(1.0, log_l1_norm(next_sum)) ->
            {:ok, next_sum}

          true ->
            log_series(value, gp(power, value), next_sum, index + 1)
        end
      end

      defp log_l1_norm(%__MODULE__{data: data}) do
        Enum.reduce(Tuple.to_list(data), 0.0, fn value, acc -> acc + abs(value) end)
      end
    end
  end
end
