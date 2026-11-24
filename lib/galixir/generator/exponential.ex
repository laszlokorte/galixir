defmodule Galixir.Generator.Exponential do
  @moduledoc """
  Generates multivector exponential, square root, logarithm and fractional powers.

  Scalar-square closed forms handle common blade and complex-like cases. General
  square roots use Newton iteration and general logarithms use inverse scaling and
  squaring with the Cayley series.
  """

  @behaviour Galixir.GeneratorBehaviour
  @impl Galixir.GeneratorBehaviour
  def generate_implementation(%Galixir.Meta{}) do
    [implementation()]
  end

  defp implementation do
    quote do
      @functional_tolerance 1.0e-12
      @functional_iteration_limit 256
      @functional_reduction_limit 32

      @doc """
      Computes the geometric-algebra exponential. Scalar-square inputs use closed
      forms; other inputs use coefficient-norm scaling, a bounded Taylor series
      with a tail bound, and repeated squaring. Raises `ArgumentError` if a
      coefficient is non-finite, the result is not representable, or the series
      fails to converge.
      """
      @doc group: :exponential
      def exp(%__MODULE__{} = value) do
        if not functional_finite?(value) do
          raise ArgumentError, "exponential requires finite coefficients"
        end

        scalar = scalar_part(value)
        body = sub(value, new(scalar: scalar))

        result =
          case functional_scalar_square(body) do
            {:ok, square} ->
              functional_exp_scalar_square(scalar, body, square)

            :error ->
              functional_exp_series(value)
          end

        if functional_finite?(result),
          do: result,
          else: raise(ArgumentError, "exponential result is not finite")
      end

      defp functional_exp_scalar_square(scalar, body, square) do
        cond do
          square < 0.0 ->
            radius = :math.sqrt(-square)
            body_exp = add(scale(:math.cos(radius), one()), scale(functional_sinc(radius), body))
            scale(:math.exp(scalar), body_exp)

          square > 0.0 ->
            radius = :math.sqrt(square)
            positive = :math.exp(scalar + radius)
            negative = :math.exp(scalar - radius)

            add(
              new(scalar: (positive + negative) / 2.0),
              scale((positive - negative) / (2.0 * radius), body)
            )

          true ->
            scale(:math.exp(scalar), add(one(), body))
        end
      end

      defp functional_exp_series(value) do
        squarings = functional_scale_exponent(value)
        scaled = scale(:math.pow(0.5, squarings), value)
        scaled_norm = functional_norm(scaled)
        tolerance = @functional_tolerance / :math.pow(2.0, squarings)

        {sum, _term, converged?} =
          Enum.reduce_while(1..@functional_iteration_limit, {one(), one(), false}, fn n,
                                                                                      {sum, term,
                                                                                       _done} ->
            next_term = scale(1.0 / n, gp(term, scaled))
            next_sum = add(sum, next_term)

            unless functional_finite?(next_term) and functional_finite?(next_sum) do
              raise ArgumentError, "exponential Taylor series produced non-finite coefficients"
            end

            term_norm = functional_norm(next_term)
            ratio = scaled_norm / (n + 1)
            tail = if ratio < 1.0, do: term_norm * ratio / (1.0 - ratio), else: :infinity

            if tail <= tolerance * max(1.0, functional_norm(next_sum)) do
              {:halt, {next_sum, next_term, true}}
            else
              {:cont, {next_sum, next_term, false}}
            end
          end)

        unless converged?, do: raise(ArgumentError, "exponential Taylor series did not converge")

        if squarings == 0 do
          sum
        else
          Enum.reduce(1..squarings, sum, fn _, acc ->
            squared = gp(acc, acc)

            if functional_finite?(squared),
              do: squared,
              else: raise(ArgumentError, "exponential overflow")
          end)
        end
      end

      @doc """
      Computes a real square root when the scalar-square formula or bounded
      Newton iteration converges. Square roots need not be unique, and Newton
      iteration is not globally convergent. `:error` means unsupported domain or
      numerical failure; it does not prove that no real square root exists.
      """
      @doc group: :exponential
      def sqrt(%__MODULE__{} = value) do
        if functional_finite?(value) do
          magnitude = functional_max(value)

          if magnitude == 0.0 do
            {:ok, zero()}
          else
            normalized = scale(1.0 / magnitude, value)

            candidate =
              case functional_sqrt_scalar_square(normalized) do
                {:ok, root} -> {:ok, root}
                :error -> functional_sqrt_newton(normalized)
              end

            with {:ok, root} <- candidate do
              root = scale(:math.sqrt(magnitude), root)
              if functional_close?(gp(root, root), value), do: {:ok, root}, else: :error
            end
          end
        else
          :error
        end
      rescue
        _error -> :error
      end

      defp functional_sqrt_scalar_square(value) do
        scalar = scalar_part(value)
        body = sub(value, new(scalar: scalar))

        case functional_scalar_square(body) do
          {:ok, square} when scalar > 0.0 and square == 0.0 ->
            {:ok,
             add(new(scalar: :math.sqrt(scalar)), scale(1.0 / (2.0 * :math.sqrt(scalar)), body))}

          {:ok, square} ->
            discriminant = scalar * scalar - square

            if discriminant >= 0.0 do
              distance = :math.sqrt(discriminant)
              leading = :math.sqrt(max(0.0, (scalar + distance) / 2.0))

              if leading > 1.0e-15 do
                candidate = add(new(scalar: leading), scale(1.0 / (2.0 * leading), body))

                if functional_close?(gp(candidate, candidate), value),
                  do: {:ok, candidate},
                  else: :error
              else
                :error
              end
            else
              :error
            end

          :error ->
            :error
        end
      end

      defp functional_sqrt_newton(value) do
        functional_sqrt_newton(value, one(), 0, nil)
      end

      defp functional_sqrt_newton(_value, _root, @functional_iteration_limit, _previous_residual),
        do: :error

      defp functional_sqrt_newton(value, root, iteration, previous_residual) do
        with {:ok, inverse} <- inverse_generic(root) do
          next = scale(0.5, add(root, gp(value, inverse)))
          residual = functional_norm(sub(gp(next, next), value))

          cond do
            not functional_finite?(next) or not functional_finite_number?(residual) ->
              :error

            residual <= @functional_tolerance * max(1.0, functional_norm(value)) ->
              {:ok, next}

            not is_nil(previous_residual) and residual >= previous_residual * (1.0 - 1.0e-14) ->
              :error

            true ->
              functional_sqrt_newton(value, next, iteration + 1, residual)
          end
        end
      end

      @doc """
      Computes a real multivector logarithm using scalar-square formulas or
      inverse scaling and squaring with the Cayley series. Every exponential is
      invertible, so singular values cannot be reached by finite exponential
      interpolation; not every invertible real multivector has a real logarithm.
      Logarithms need not be unique, and a real logarithm may exist outside the
      subalgebra generated by the input. This algorithm may fail even when a real
      logarithm exists (for example, for a negative scalar it does not search for
      a square-negative element elsewhere in the algebra). `{:error, reason}`
      indicates unsupported domain or numerical failure, not proof that no real
      logarithm exists. The selected logarithm is checked by reconstruction and
      commutation residuals.
      """
      @doc group: :exponential
      def log(%__MODULE__{} = value) do
        magnitude = functional_max(value)

        if not functional_finite?(value) or magnitude == 0.0 do
          {:error, :outside_domain}
        else
          normalized = scale(1.0 / magnitude, value)

          result =
            case functional_log_scalar_square(normalized) do
              {:ok, candidate} -> {:ok, add(new(scalar: :math.log(magnitude)), candidate)}
              :error -> functional_log_general(normalized, magnitude)
            end

          with {:ok, candidate} <- result,
               true <- functional_finite?(candidate),
               true <- functional_close?(exp(candidate), value),
               true <- functional_commutes?(candidate, value) do
            {:ok, candidate}
          else
            _ -> {:error, :no_convergence}
          end
        end
      rescue
        _error -> {:error, :no_convergence}
      end

      defp functional_log_scalar_square(value) do
        scalar = scalar_part(value)
        body = sub(value, new(scalar: scalar))

        if functional_max(body) == 0.0 and scalar > 0.0 do
          {:ok, new(scalar: :math.log(scalar))}
        else
          case functional_scalar_square(body) do
            {:ok, square} when square < 0.0 ->
              radius = :math.sqrt(-square)
              magnitude = functional_hypot(scalar, radius)
              angle = :math.atan2(radius, scalar)
              {:ok, add(new(scalar: :math.log(magnitude)), scale(angle / radius, body))}

            {:ok, square} when square == 0.0 and scalar > 0.0 ->
              {:ok, add(new(scalar: :math.log(scalar)), scale(1.0 / scalar, body))}

            {:ok, square} when square > 0.0 ->
              radius = :math.sqrt(square)

              if scalar > radius do
                plus = :math.log(scalar + radius)
                minus = :math.log(scalar - radius)
                scalar_log = (plus + minus) / 2.0
                body_factor = (plus - minus) / (2.0 * radius)
                {:ok, add(new(scalar: scalar_log), scale(body_factor, body))}
              else
                :error
              end

            _ ->
              :error
          end
        end
      end

      defp functional_log_general(value, magnitude) do
        case functional_log_reduce(value, 0) do
          {:ok, reduced_log, roots} ->
            {:ok,
             add(new(scalar: :math.log(magnitude)), scale(:math.pow(2.0, roots), reduced_log))}

          :error ->
            :error
        end
      end

      defp functional_log_reduce(_value, @functional_reduction_limit), do: :error

      defp functional_log_reduce(value, roots) do
        with {:ok, z} <- functional_cayley(value),
             norm when norm <= 0.5 <- functional_norm(z) do
          case functional_cayley_series(z, roots) do
            {:ok, result} -> {:ok, result, roots}
            :error -> :error
          end
        else
          _ ->
            with {:ok, root} <- sqrt(value),
                 true <- not functional_close?(root, value) do
              functional_log_reduce(root, roots + 1)
            else
              _ -> :error
            end
        end
      end

      defp functional_cayley(value) do
        denominator = add(value, one())

        with {:ok, inverse} <- inverse_generic(denominator) do
          {:ok, gp(sub(value, one()), inverse)}
        end
      end

      defp functional_cayley_series(z, roots) do
        z2 = gp(z, z)
        q = functional_norm(z)
        tolerance = @functional_tolerance / :math.pow(2.0, roots + 1)

        Enum.reduce_while(1..@functional_iteration_limit, {:continue, z, z}, fn n,
                                                                                {:continue, sum,
                                                                                 power} ->
          next_power = gp(power, z2)
          divisor = 2 * n + 1
          term = scale(1.0 / divisor, next_power)
          next_sum = add(sum, term)

          tail =
            2.0 * :math.pow(q, 2 * n + 3) /
              ((2 * n + 3) * (1.0 - q * q))

          cond do
            not functional_finite?(next_sum) ->
              {:halt, :error}

            tail <= tolerance ->
              {:halt, {:ok, scale(2.0, next_sum)}}

            true ->
              {:cont, {:continue, next_sum, next_power}}
          end
        end)
        |> case do
          {:ok, result} -> {:ok, result}
          _ -> :error
        end
      end

      @doc "Returns `{:ok, result}` for the real fractional power, or `:error` when its logarithm is unsupported."
      @doc group: :exponential
      def pow(%__MODULE__{} = value, exponent) when is_number(exponent) do
        with true <- functional_finite_number?(exponent),
             {:ok, logarithm} <- log(value) do
          result = exp(scale(exponent, logarithm))
          if functional_finite?(result), do: {:ok, result}, else: :error
        else
          _ -> :error
        end
      rescue
        _error -> :error
      end

      def pow(_value, _exponent), do: :error

      defp functional_scalar_square(value) do
        product = gp(value, value)
        scalar = scalar_part(product)
        nonscalar = sub(product, new(scalar: scalar))
        relative_residual = functional_max(nonscalar) / max(1.0, functional_max(product))

        if relative_residual <= @functional_tolerance, do: {:ok, scalar}, else: :error
      end

      defp functional_sinc(value) when abs(value) < 1.0e-4 do
        square = value * value
        1.0 - square / 6.0 + square * square / 120.0
      end

      defp functional_sinc(value), do: :math.sin(value) / value

      defp functional_hypot(a, b) do
        maximum = max(abs(a), abs(b))

        if maximum == 0.0,
          do: 0.0,
          else: maximum * :math.sqrt((a / maximum) ** 2 + (b / maximum) ** 2)
      end

      defp functional_scale_exponent(%__MODULE__{data: data}) do
        maximum = Enum.reduce(Tuple.to_list(data), 0.0, fn value, acc -> max(abs(value), acc) end)

        if maximum == 0.0 do
          0
        else
          scaled_norm =
            Enum.reduce(Tuple.to_list(data), 0.0, fn value, acc -> acc + abs(value) / maximum end)

          max(0, ceil(:math.log2(maximum) + :math.log2(scaled_norm) + 1.0))
        end
      end

      defp functional_norm(%__MODULE__{data: data}) do
        Enum.reduce(Tuple.to_list(data), 0.0, fn value, acc -> acc + abs(value) end)
      end

      defp functional_max(%__MODULE__{data: data}) do
        Enum.reduce(Tuple.to_list(data), 0.0, fn value, acc -> max(abs(value), acc) end)
      end

      defp functional_finite?(%__MODULE__{data: data}) do
        Enum.all?(Tuple.to_list(data), &functional_finite_number?/1)
      end

      defp functional_finite_number?(value) when is_float(value), do: value * 0.0 == 0.0

      defp functional_finite_number?(value) when is_integer(value) do
        _ = value * 1.0
        true
      rescue
        ArithmeticError -> false
      end

      defp functional_finite_number?(_value), do: false

      defp functional_close?(actual, expected) do
        residual = functional_max(sub(actual, expected))
        residual / max(1.0, functional_max(expected)) <= @functional_tolerance
      end

      defp functional_commutes?(a, b) do
        residual = functional_max(commutator(a, b))

        residual / max(1.0, functional_max(a)) / max(1.0, functional_max(b)) <=
          @functional_tolerance
      end
    end
  end
end
