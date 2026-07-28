defmodule BladeGuardTest do
  use ExUnit.Case

  alias Galixir.Algebras.PGA3
  require Galixir.Algebras.PGA3

  defp test_blade(mv) when PGA3.is_blade(mv), do: true
  defp test_blade(_), do: false

  test "zero multivector is a blade" do
    assert test_blade(PGA3.new())
    assert PGA3.grade?(PGA3.new(), 0)
  end

  test "scalar is a blade" do
    assert test_blade(PGA3.new(scalar: 1))
    assert test_blade(PGA3.new(scalar: -5))
    assert PGA3.grade?(PGA3.new(scalar: 5), 0)
  end

  test "multiple scalar values do not matter" do
    assert test_blade(PGA3.new(scalar: 10))
  end

  test "vectors of same grade are blades" do
    assert test_blade(PGA3.new(e1: 1))
    assert test_blade(PGA3.new(e1: 1, e2: 2))
    assert test_blade(PGA3.new(e1: 1, e2: 2, e3: 3))

    assert PGA3.grade?(PGA3.new(e1: 1), 1)
    assert PGA3.grade?(PGA3.new(e1: 1, e2: 2), 1)
    assert PGA3.grade?(PGA3.new(e1: 1, e2: 2, e3: 3), 1)
  end

  test "bivectors of same grade are blades" do
    assert test_blade(PGA3.new(e12: 1))
    assert test_blade(PGA3.new(e12: 1, e13: 2))
    assert test_blade(PGA3.new(e12: 1, e13: 2, e23: 3))

    assert PGA3.grade(PGA3.new(e12: 1), 2)
    assert PGA3.grade(PGA3.new(e12: 1, e13: 2), 2)
    assert PGA3.grade(PGA3.new(e12: 1, e13: 2, e23: 3), 2)
  end

  test "trivectors of same grade are blades" do
    assert test_blade(PGA3.new(e123: 1))
  end

  test "mixed scalar and vector are not blades" do
    v = PGA3.new(scalar: 1, e1: 1)
    refute test_blade(v)

    for g <- 1..4 do
      refute PGA3.grade?(v, g)
    end
  end

  test "mixed vector and bivector are not blades" do
    v = PGA3.new(e1: 1, e12: 1)
    refute test_blade(v)

    for g <- 1..4 do
      refute PGA3.grade?(v, g)
    end
  end

  test "mixed vector and trivector are not blades" do
    v = PGA3.new(e1: 1, e123: 1)
    refute test_blade(v)

    for g <- 1..4 do
      refute PGA3.grade?(PGA3.new(e12: 1, e123: 1), g)
    end
  end

  test "mixed bivector and trivector are not blades" do
    v = PGA3.new(e12: 1, e123: 1)
    refute test_blade(v)

    for g <- 1..4 do
      refute PGA3.grade?(PGA3.new(e12: 1, e123: 1), g)
    end
  end

  test "multiple mixed grades are not blades" do
    v =
      PGA3.new(
        scalar: 1,
        e1: 2,
        e12: 3,
        e123: 4
      )

    refute test_blade(v)

    for g <- 1..4 do
      refute PGA3.grade?(PGA3.new(e12: 1, e123: 1), g)
    end
  end

  test "ideal basis vectors are still grade one" do
    assert test_blade(PGA3.new(e0: 1))
    assert test_blade(PGA3.new(e1: 1, e0: 2))

    assert PGA3.grade?(PGA3.new(e0: 1), 1)
    assert PGA3.grade?(PGA3.new(e1: 1, e0: 2), 1)
  end

  test "ideal mixed grades are rejected" do
    v = PGA3.new(e0: 1, e10: 1)
    refute test_blade(v)

    for g <- 1..4 do
      refute PGA3.grade?(PGA3.new(e12: 1, e123: 1), g)
    end
  end
end
