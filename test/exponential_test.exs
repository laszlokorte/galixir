defmodule ExponentialTest do
  use ExUnit.Case, async: true
  @eps 1.0e-12

  alias Galixir.Algebras.{CGA2, CGA3, Complex1, Dual1, Hyper1, PGA2, PGA3, PGA4, Vector2}

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

  test "scalar logarithms round-trip throughout the supported positive domain" do
    for algebra <- [PGA2, PGA3, PGA4, CGA2, CGA3], value <- [0.25, 0.75, 1.0, 1.5] do
      {:ok, result} = algebra.log(algebra.new(scalar: value))
      assert_in_delta algebra.scalar_part(result), :math.log(value), @eps

      {:ok, recovered} = algebra.log(algebra.exp(result))
      assert_in_delta algebra.scalar_part(recovered), :math.log(value), @eps
    end
  end

  test "logarithms recover small nilpotent and bivector generators in every target algebra" do
    for algebra <- [PGA2, PGA3, PGA4, CGA2, CGA3] do
      nilpotent =
        if algebra in [CGA2, CGA3],
          do: algebra.scale(0.1, algebra.e_inf()),
          else: algebra.new(e0: 0.1)

      {:ok, nilpotent_recovered} = nilpotent |> algebra.exp() |> algebra.log()
      assert_multivectors_close(nilpotent_recovered, nilpotent, @eps)

      bivector = algebra.new(e12: 0.1)
      {:ok, bivector_recovered} = bivector |> algebra.exp() |> algebra.log()
      assert_multivectors_close(bivector_recovered, bivector, @eps)
    end
  end

  test "singular scalar inputs are rejected by the local real logarithm" do
    for algebra <- [PGA2, PGA3, PGA4, CGA2, CGA3] do
      assert match?({:error, _}, algebra.log(algebra.new()))
      assert match?({:error, _}, algebra.log(algebra.new(scalar: -0.5)))
    end
  end

  test "generic functional calculus covers complex, dual, split-complex and vector algebras" do
    for algebra <- [Complex1, Dual1, Hyper1, Vector2] do
      value = algebra.new(scalar: 0.2, e1: 0.1)
      exponential = algebra.exp(value)
      assert_finite(exponential)
      assert {:ok, logarithm} = algebra.log(exponential)
      assert_multivectors_close(logarithm, value, @eps)
      assert {:ok, square_root} = algebra.sqrt(exponential)
      assert_multivectors_close(algebra.gp(square_root, square_root), exponential, @eps)
      assert {:ok, half_power} = algebra.pow(exponential, 0.5)
      assert_multivectors_close(algebra.gp(half_power, half_power), exponential, @eps)
    end
  end

  test "square root handles scalar-square and generic Newton cases" do
    for algebra <- [PGA3, CGA3] do
      positive = algebra.new(scalar: 4.0)
      assert {:ok, positive_root} = algebra.sqrt(positive)
      assert_multivectors_close(algebra.gp(positive_root, positive_root), positive, @eps)

      generator =
        if algebra == CGA3 do
          algebra.new(scalar: 1.0, e1: 0.1, e2: 0.05, e12: 0.025)
        else
          algebra.new(scalar: 1.0, e1: 0.1, e2: 0.05, e0: 0.025)
        end

      square = algebra.gp(generator, generator)
      assert {:ok, root} = algebra.sqrt(square)
      assert_multivectors_close(algebra.gp(root, root), square, 1.0e-9)
    end
  end

  test "generic exponential agrees with its inverse and addition for commuting inputs" do
    for algebra <- [PGA3, CGA3] do
      a = algebra.new(scalar: 0.2, e1: 0.05, e12: 0.02)
      b = algebra.scale(-0.5, a)

      assert_multivectors_close(
        algebra.gp(algebra.exp(a), algebra.exp(algebra.scale(-1, a))),
        algebra.one(),
        @eps
      )

      assert_multivectors_close(
        algebra.exp(algebra.add(a, b)),
        algebra.gp(algebra.exp(a), algebra.exp(b)),
        @eps
      )
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
    exponential = CGA3.exp(value)

    assert_multivectors_close(exponential, reference_exp(CGA3, value), @eps)
    assert {:ok, logarithm} = CGA3.log(exponential)
    assert_multivectors_close(CGA3.exp(logarithm), exponential, 1.0e-9)
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
    assert match?({:error, _}, PGA3.log(PGA3.new(scalar: -1)))
    assert {:ok, positive_log} = PGA3.log(PGA3.new(scalar: 3))
    assert_in_delta PGA3.scalar_part(positive_log), :math.log(3), @eps

    non_finite = PGA3.new({:not_a_number, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
    assert match?({:error, _}, PGA3.log(non_finite))

    assert_raise ArgumentError, ~r/finite/, fn -> PGA3.exp(non_finite) end
  end

  test "generic logarithm handles nonsimple CGA3 bivectors and nearly null components" do
    nonsimple_bivector = CGA3.new(e12: 0.12, e3p: -0.08)
    square = CGA3.gp(nonsimple_bivector, nonsimple_bivector)
    nonscalar_square = CGA3.sub(square, CGA3.new(scalar: CGA3.scalar_part(square)))
    refute Enum.all?(Tuple.to_list(nonscalar_square.data), &(abs(&1) <= 1.0e-12))

    exponential = CGA3.exp(nonsimple_bivector)
    assert {:ok, logarithm} = CGA3.log(exponential)
    assert_multivectors_close(CGA3.exp(logarithm), exponential, 1.0e-9)
    assert_multivectors_close(CGA3.commutator(logarithm, exponential), CGA3.zero(), 1.0e-9)

    nearly_null = CGA3.scale(1.0e-10, CGA3.e_inf())
    nearly_null_exponential = CGA3.exp(nearly_null)
    assert {:ok, nearly_null_logarithm} = CGA3.log(nearly_null_exponential)
    assert_multivectors_close(nearly_null_logarithm, nearly_null, 1.0e-12)
  end

  test "generic exponential handles mixed-grade inputs requiring repeated squaring" do
    value = CGA3.new(scalar: 0.5, e1: 8.0, e12: -4.0, e123p: 2.0)
    exponential = CGA3.exp(value)
    inverse_exponential = CGA3.exp(CGA3.scale(-1.0, value))

    assert_finite(exponential)
    assert_multivectors_close(CGA3.gp(exponential, inverse_exponential), CGA3.one(), 1.0e-8)
  end

  test "square root failures are explicit for unsupported and singular domains" do
    assert PGA3.sqrt(PGA3.new(scalar: -1.0)) == :error
    assert PGA3.sqrt(PGA3.new(e0: 1.0)) == :error
    assert PGA3.sqrt(PGA3.zero()) == {:ok, PGA3.zero()}
  end

  test "CGA3 screw logarithms reconstruct the original transformation" do
    import Galixir.Algebras.CGA3, only: [sigil_G: 2]

    motor =
      ~G[ -0.2102735335060552 - 0.8210680832141203e13 - 0.5306903464676631e23 - 1.3e3p - 1.3e3m ]

    assert {:ok, logarithm} = CGA3.log(motor)
    assert_multivectors_close(CGA3.exp(logarithm), motor, 1.0e-8)
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
