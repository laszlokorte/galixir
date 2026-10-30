defmodule ExponentialTest do
  use ExUnit.Case, async: true
  @eps 1.0e-14

  alias Galixir.Algebras.{CGA2, CGA3, PGA2, PGA3, PGA4}

  test "every generated target algebra has the exponential and local logarithm" do
    for algebra <- [PGA2, PGA3, PGA4, CGA2, CGA3] do
      one = algebra.one()
      assert algebra.exp(algebra.new()) == one
      assert algebra.log(one) == {:ok, algebra.new()}

      value = algebra.new(scalar: 0.1, e1: 0.05)
      {:ok, recovered} = algebra.log(algebra.exp(value))
      assert_multivectors_close(recovered, value, @eps)
    end
  end

  test "scalar exponentials agree with the real exponential" do
    for value <- [-3.0, -0.25, 0.0, 1.0, 4.0] do
      result = PGA3.exp(PGA3.new(scalar: value))

      assert_in_delta PGA3.scalar_part(result),
                      :math.exp(value),
                      @eps * max(1.0, :math.exp(value))

      assert Enum.all?(Tuple.to_list(result.data) |> tl(), &(abs(&1) < 1.0e-14))
    end
  end

  test "exponential handles nilpotent and Euclidean bivector generators" do
    nilpotent = PGA3.new(e0: 2)
    assert PGA3.exp(nilpotent) == PGA3.add(PGA3.one(), nilpotent)

    angle = 0.7
    rotation_generator = PGA3.new(e12: angle)
    rotation = PGA3.exp(rotation_generator)

    assert_in_delta PGA3.scalar_part(rotation), :math.cos(angle), @eps
    assert_in_delta PGA3.coefficient(rotation, :e12), :math.sin(angle), @eps
  end

  test "mixed-grade exponential agrees with an independent Taylor reference" do
    value = CGA3.new(scalar: 0.1, e1: -0.04, e12: 0.03, e123p: 0.02)

    assert_multivectors_close(CGA3.exp(value), reference_exp(CGA3, value), @eps)
  end

  test "app regression exponentials remain finite for mixed and motor-like inputs" do
    import Galixir.Algebras.CGA3, only: [sigil_G: 2]

    inputs = [
      ~G[ -0.2102735335060552 - 0.8210680832141203e13 - 0.5306903464676631e23 - 1.3e3p - 1.3e3m ],
      ~G[ -0.41666666666666663e3p + 0.75e13p - 1.0833333333333333e3m + 1.25e13m ],
      ~G[ -1.0e23 - 1.0e123p - 1.0e123m ]
    ]

    for value <- inputs do
      assert_finite(CGA3.exp(value))
    end
  end

  test "logarithm reports values outside its local real branch" do
    assert PGA3.log(PGA3.new(scalar: -1)) == {:error, :outside_convergence_domain}
    assert PGA3.log(PGA3.new(scalar: 3)) == {:error, :outside_convergence_domain}
    assert PGA3.log(PGA3.new(scalar: 1.9999)) == {:error, :no_convergence}

    non_finite = PGA3.new({:not_a_number, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
    assert PGA3.log(non_finite) == {:error, :non_finite}

    assert_raise ArgumentError, ~r/non-finite/, fn -> PGA3.exp(non_finite) end
  end

  test "the previously unstable CGA3 motor logarithm fails explicitly outside the local domain" do
    import Galixir.Algebras.CGA3, only: [sigil_G: 2]

    motor =
      ~G[ -0.2102735335060552 - 0.8210680832141203e13 - 0.5306903464676631e23 - 1.3e3p - 1.3e3m ]

    assert {:error, reason} = CGA3.log(motor)
    assert reason in [:outside_convergence_domain, :no_convergence]
  end

  defp reference_exp(algebra, value) do
    Enum.reduce(1..120, {algebra.one(), algebra.one()}, fn index, {sum, term} ->
      term = algebra.scale(1.0 / index, algebra.gp(term, value))
      {algebra.add(sum, term), term}
    end)
    |> elem(0)
  end

  defp assert_multivectors_close(actual, expected, tolerance) do
    actual
    |> Map.fetch!(:data)
    |> Tuple.to_list()
    |> Enum.zip(Tuple.to_list(expected.data))
    |> Enum.each(fn {left, right} -> assert_in_delta(left, right, tolerance) end)
  end

  defp assert_finite(%{data: data}) do
    assert Enum.all?(Tuple.to_list(data), fn value ->
             is_integer(value) or (is_float(value) and value * 0.0 == 0.0)
           end)
  end
end
