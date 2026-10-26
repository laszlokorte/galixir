defmodule GeometricAlgebraOptionsTest do
  use ExUnit.Case

  defmodule DefaultBases do
    use Galixir.GeometricAlgebra, metric: {1, -1}
  end

  defmodule CustomBases do
    use Galixir.GeometricAlgebra, metric: {1, 0}, bases: {"x", "y"}, epsilon: 0.0
  end

  test "omitted bases default to numbered strings" do
    assert DefaultBases.gp(DefaultBases.new(e1: 1), DefaultBases.new(e1: 1)) ==
             DefaultBases.new(scalar: 1)

    assert DefaultBases.gp(DefaultBases.new(e2: 1), DefaultBases.new(e2: 1)) ==
             DefaultBases.new(scalar: -1)
  end

  test "custom names and zero epsilon are supported" do
    assert CustomBases.parse("ex + ey") == CustomBases.new(ex: 1, ey: 1)
    assert CustomBases.epsilon() == 0.0
  end

  test "invalid options fail with actionable errors" do
    cases = [
      {[metric: {}], "nonempty tuple"},
      {[metric: [1, 1]], "nonempty tuple"},
      {[metric: {2}], "Each metric element"},
      {[metric: {1, 1}, bases: ["1", "2"]], ":bases must be a tuple"},
      {[metric: {1, 1}, bases: {"1", "1"}], "must be unique"},
      {[metric: {1, 1}, bases: {"1"}], "number of bases"},
      {[metric: {1}, bases: {"long"}], "length 1"},
      {[metric: {1}, epsilon: -1.0], "non-negative"},
      {[metric: {1}, epsilon: 0], "floating point"},
      {[metric: List.to_tuple(List.duplicate(1, 10))], "supplied explicitly"}
    ]

    for {opts, message} <- cases do
      assert_raise ArgumentError, ~r/#{Regex.escape(message)}/, fn ->
        Module.create(
          Module.concat(__MODULE__, Invalid),
          quote(do: use(Galixir.GeometricAlgebra, unquote(Macro.escape(opts)))),
          Macro.Env.location(__ENV__)
        )
      end
    end
  end
end
