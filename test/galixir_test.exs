defmodule GalixirTest do
  use ExUnit.Case
  doctest Galixir
  doctest Galixir.Blade
  doctest Galixir.Generator
  doctest Galixir.Table
  doctest Galixir.GeometricAlgebra

  alias Galixir.Algebras.PGA2
  alias Galixir.Algebras.PGA3
  alias Galixir.Table

  test "dimension" do
    assert PGA2.dimension() == 3
    assert PGA3.dimension() == 4
  end

  test "multiply" do
    assert Galixir.Blade.multiply(1, 1, {1, 1, 0}) == {1, 0}
  end

  test "blades" do
    # e1 * e2 = e12
    assert Galixir.Blade.multiply(1, 2, {1, 1, 0}) == {1, 3}

    # e2 * e1 = -e12
    assert Galixir.Blade.multiply(2, 1, {1, 1, 0}) == {-1, 3}

    # e3 * e3 = 0
    assert Galixir.Blade.multiply(4, 4, {1, 1, 0}) == {0, 0}
  end

  test "table" do
    table = Table.build({1, 1, 0})
    table2 = Table.build({1, 1, 1})

    assert table[{1, 1}] == {1, 0}
    assert table[{1, 2}] == {1, 3}
    assert table[{2, 1}] == {-1, 3}

    assert table2[{1, 2}] == {1, 3}
  end

  test "PGA2 metric" do
    zero = {0, 0, 0, 0, 0, 0, 0, 0}

    one = {1, 0, 0, 0, 0, 0, 0, 0}

    e2 = {0, 0, 1, 0, 0, 0, 0, 0}
    e3 = {0, 0, 0, 0, 1, 0, 0, 0}

    e1 = {0, 1, 0, 0, 0, 0, 0, 0}
    assert PGA2.gp(e1, e1) == one
    assert PGA2.gp(e2, e2) == one
    assert PGA2.gp(e3, e3) == zero
  end

  test "basis vectors anticommute" do
    e1 = {0, 1, 0, 0, 0, 0, 0, 0}
    e2 = {0, 0, 1, 0, 0, 0, 0, 0}

    assert PGA2.gp(e1, e2) ==
             {0, 0, 0, 1, 0, 0, 0, 0}

    assert PGA2.gp(e2, e1) ==
             {0, 0, 0, -1, 0, 0, 0, 0}
  end

  test "multivector multiplication" do
    # 1 + e1
    a = {1, 1, 0, 0, 0, 0, 0, 0}
    # 1 + e2
    b = {1, 0, 1, 0, 0, 0, 0, 0}

    assert PGA2.gp(a, b) ==
             {1, 1, 1, 1, 0, 0, 0, 0}
  end

  test "identity" do
    one = {1, 0, 0, 0, 0, 0, 0, 0}

    for i <- 0..7 do
      x = List.to_tuple(for j <- 0..7, do: if(i == j, do: 1, else: 0))

      assert PGA2.gp(one, x) == x
      assert PGA2.gp(x, one) == x
    end
  end

  test "associativity" do
    blades =
      for i <- 0..7 do
        List.to_tuple(for j <- 0..7, do: if(i == j, do: 1, else: 0))
      end

    for a <- blades,
        b <- blades,
        c <- blades do
      assert PGA2.gp(PGA2.gp(a, b), c) ==
               PGA2.gp(a, PGA2.gp(b, c))
    end
  end

  test "left distributivity" do
    a = {1, 1, 0, 2, 0, 0, 0, 0}
    b = {0, 1, 3, 0, 0, 0, 0, 0}
    c = {2, 0, 1, 0, 0, 0, 0, 0}

    left =
      PGA2.gp(
        tuple_add(a, b),
        c
      )

    right =
      tuple_add(
        PGA2.gp(a, c),
        PGA2.gp(b, c)
      )

    assert left == right
  end

  test "random associativity" do
    for _ <- 1..100 do
      a = random_mv()
      b = random_mv()
      c = random_mv()

      assert PGA2.gp(PGA2.gp(a, b), c) ==
               PGA2.gp(a, PGA2.gp(b, c))
    end
  end

  test "addition" do
    a = {1, 2, 3, 4, 0, 0, 0, 0}
    b = {5, 6, 7, 8, 1, 2, 3, 4}

    assert PGA2.add(a, b) ==
             {6, 8, 10, 12, 1, 2, 3, 4}
  end

  test "subtraction" do
    a = {1, 2, 3, 4, 0, 0, 0, 0}
    b = {5, 6, 7, 8, 1, 2, 3, 4}

    assert PGA2.sub(a, b) ==
             {-4, -4, -4, -4, -1, -2, -3, -4}
  end

  test "scalar multiplication" do
    a = {1, -2, 3, -4, 5, -6, 7, -8}

    assert PGA2.scale(3, a) ==
             {3, -6, 9, -12, 15, -18, 21, -24}

    assert PGA2.scale(0, a) ==
             {0, 0, 0, 0, 0, 0, 0, 0}

    assert PGA2.scale(a, 3) ==
             {3, -6, 9, -12, 15, -18, 21, -24}

    assert PGA2.scale(a, 0) ==
             {0, 0, 0, 0, 0, 0, 0, 0}
  end

  test "geometric product linearity" do
    # 1 + e1
    a = {1, 1, 0, 0, 0, 0, 0, 0}
    # 1 + e2
    b = {1, 0, 1, 0, 0, 0, 0, 0}
    # e3
    c = {0, 0, 0, 0, 1, 0, 0, 0}

    assert PGA2.gp(a, b) ==
             {1, 1, 1, 1, 0, 0, 0, 0}

    assert PGA2.gp(c, a) ==
             {0, 0, 0, 0, 1, -1, 0, 0}
  end

  test "gp distributes over addition" do
    a = {1, 2, 3, 4, 5, 6, 7, 8}
    b = {2, 3, 4, 5, 6, 7, 8, 9}
    c = {9, 8, 7, 6, 5, 4, 3, 2}

    assert PGA2.gp(PGA2.add(a, b), c) ==
             PGA2.add(PGA2.gp(a, c), PGA2.gp(b, c))
  end

  test "inspect" do
    a = PGA2.new({0, 1, 0, 0, 1, 0, 0, 0})
    b = PGA2.new({0, 0, 1, 1, 0, 0, 0, 0})

    assert PGA2.add(a, b) |> PGA2.gp(a) |> inspect == "1 - e2 - e12 + e20 + e120"
  end

  test "scalars" do
    a = PGA2.new(scalar: 1)
    b = PGA2.new(scalar: 2)

    assert PGA2.add(a, b) |> inspect == "3"
    assert PGA2.gp(a, b) |> inspect == "2"
  end

  test "named new" do
    a = PGA2.new(e1: 1, e0: 1)
    b = PGA2.new(e2: 1, e12: 1)

    assert PGA2.add(a, b) |> PGA2.gp(a) |> inspect == "1 - e2 - e12 + e20 + e120"

    assert PGA2.new({1, 2, 3, 4, 5, 6, 7, 8}) ==
             PGA2.new(scalar: 1, e1: 2, e2: 3, e12: 4, e0: 5, e10: 6, e20: 7, e120: 8)
  end

  test "reverse" do
    e1 =
      PGA2.new(e1: 1)

    e12 =
      PGA2.new(e12: 1)

    e120 =
      PGA2.new(e120: 1)

    assert PGA2.reverse(e1) ==
             e1

    assert PGA2.reverse(e12) ==
             PGA2.new(e12: -1)

    assert PGA2.reverse(e120) ==
             PGA2.new(e120: -1)
  end

  test "grade extraction" do
    a =
      PGA2.new(
        scalar: 1,
        e1: 2,
        e12: 3,
        e0: 4,
        e120: 5
      )

    assert PGA2.grade(a, 0) ==
             PGA2.new(scalar: 1)

    assert PGA2.grade(a, 1) ==
             PGA2.new(e1: 2, e0: 4)

    assert PGA2.grade(a, 2) ==
             PGA2.new(e12: 3)

    assert PGA2.grade(a, 3) ==
             PGA2.new(e120: 5)
  end

  test "grade of homogeneous blade" do
    e12 = PGA2.new(e12: 7)

    assert PGA2.grade(e12, 2) == e12
    assert PGA2.grade(e12, 1) == PGA2.new()
  end

  test "grade preserves zero" do
    zero = PGA2.new()

    for g <- 0..3 do
      assert PGA2.grade(zero, g) == zero
    end
  end

  test "grade is a projection" do
    a =
      PGA2.new(
        scalar: 1,
        e1: 2,
        e20: 3,
        e120: 4
      )

    assert PGA2.grade(PGA2.grade(a, 1), 1) ==
             PGA2.grade(a, 1)
  end

  test "invalid grade raises" do
    assert_raise ArgumentError, fn ->
      PGA2.grade(PGA2.new(e1: 1), 4)
    end
  end

  test "outer product of basis vectors" do
    e1 = PGA2.new(e1: 1)
    e2 = PGA2.new(e2: 1)

    assert PGA2.wedge(e1, e2) ==
             PGA2.new(e12: 1)

    assert PGA2.wedge(e2, e1) ==
             PGA2.new(e12: -1)
  end

  test "outer product removes repeated vectors" do
    e1 = PGA2.new(e1: 1)

    assert PGA2.wedge(e1, e1) ==
             PGA2.new()
  end

  test "outer product of higher blades" do
    e12 = PGA2.new(e12: 1)
    e0 = PGA2.new(e0: 1)

    assert PGA2.wedge(e12, e0) ==
             PGA2.new(e120: 1)
  end

  test "outer product is antisymmetric for vectors" do
    e1 = PGA2.new(e1: 1)
    e2 = PGA2.new(e2: 1)

    assert PGA2.wedge(e1, e2) == PGA2.scale(-1, PGA2.wedge(e2, e1))
  end

  test "inner product of vectors" do
    e1 = PGA2.new(e1: 1)
    e2 = PGA2.new(e2: 1)
    e0 = PGA2.new(e0: 1)

    assert PGA2.inner(e1, e1) ==
             PGA2.new(scalar: 1)

    assert PGA2.inner(e2, e2) ==
             PGA2.new(scalar: 1)

    assert PGA2.inner(e0, e0) ==
             PGA2.new()

    assert PGA2.inner(e1, e2) ==
             PGA2.new()
  end

  test "vector bivector contraction" do
    e1 = PGA2.new(e1: 1)
    e12 = PGA2.new(e12: 1)

    assert PGA2.inner(e1, e12) ==
             PGA2.new(e2: 1)
  end

  test "inner product grade" do
    a = PGA2.new(e12: 1)
    b = PGA2.new(e120: 1)

    assert PGA2.inner(a, b) ==
             PGA2.new(e0: -1)
  end

  test "scalar product" do
    e1 = PGA2.new(e1: 1)
    e2 = PGA2.new(e2: 1)
    e0 = PGA2.new(e0: 1)

    assert PGA2.scalar_product(e1, e1) == 1
    assert PGA2.scalar_product(e2, e2) == 1
    assert PGA2.scalar_product(e0, e0) == 0

    assert PGA2.scalar_product(e1, e2) == 0
  end

  test "scalar product bivectors" do
    e12 = PGA2.new(e12: 1)

    assert PGA2.scalar_product(e12, e12) == -1
  end

  test "inverse of bivector" do
    e12 = PGA2.new(e12: 1)

    assert PGA2.gp(e12, PGA2.inverse(e12)) ==
             PGA2.new(scalar: 1)
  end

  test "inverse of vector" do
    e1 = PGA2.new(e1: 1)
    e2 = PGA2.new(e2: 1)

    assert PGA2.gp(e1, PGA2.inverse(e1)) ==
             PGA2.new(scalar: 1)

    assert PGA2.gp(e2, PGA2.inverse(e2)) ==
             PGA2.new(scalar: 1)
  end

  test "inverse of scalar" do
    a = PGA2.new(scalar: 5)

    assert PGA2.inverse(a) ==
             PGA2.new(scalar: 0.2)
  end

  test "pseudoscalar is not invertible" do
    i = PGA2.new(e120: 1)

    assert PGA2.scalar_product(i, PGA2.reverse(i)) == 0
  end

  test "inverse rejects null vectors" do
    e3 = PGA2.new(e0: 1)

    assert_raise ArgumentError, fn ->
      PGA2.inverse(e3)
    end
  end

  test "inverse rejects null pseudoscalar" do
    i = PGA2.new(e120: 1)

    assert_raise ArgumentError, fn ->
      PGA2.inverse(i)
    end
  end

  test "inverse property" do
    for a <- [
          PGA2.new(e1: 1),
          PGA2.new(e2: 1),
          PGA2.new(e12: 1),
          PGA2.new(scalar: 7)
        ] do
      assert PGA2.gp(a, PGA2.inverse(a)) ==
               PGA2.new(scalar: 1)
    end
  end

  test "inverse property right multiplication" do
    a = PGA2.new(e12: 1)

    assert PGA2.gp(PGA2.inverse(a), a) ==
             PGA2.new(scalar: 1)
  end

  test "scalar?" do
    assert PGA2.scalar?(PGA2.new(scalar: 5))

    refute PGA2.scalar?(PGA2.new(e1: 1))
    refute PGA2.scalar?(PGA2.new(e12: 1))

    assert PGA2.scalar?(PGA2.new())
  end

  test "geometric product identity" do
    one = PGA2.new(scalar: 1)

    for a <- [
          PGA2.new(e1: 1),
          PGA2.new(e2: 1),
          PGA2.new(e12: 1),
          PGA2.new(e1: 2, e20: 3)
        ] do
      assert PGA2.gp(one, a) == a
      assert PGA2.gp(a, one) == a
    end
  end

  test "reverse is involution" do
    for a <- [
          PGA2.new(e1: 1, e12: 2),
          PGA2.new(e120: 1),
          PGA2.new(scalar: 5)
        ] do
      assert PGA2.reverse(PGA2.reverse(a)) == a
    end
  end

  test "scalar product symmetry" do
    a = PGA2.new(e1: 2, e12: 3)
    b = PGA2.new(e2: 4, e20: 5)

    assert PGA2.scalar_product(a, b) ==
             PGA2.scalar_product(b, a)
  end

  test "multivector associativity" do
    a = PGA2.new(e1: 2, e12: -1)
    b = PGA2.new(e2: 3, e20: 4)
    c = PGA2.new(e0: 5, e120: 1)

    assert PGA2.gp(PGA2.gp(a, b), c) ==
             PGA2.gp(a, PGA2.gp(b, c))
  end

  test "reverse reverses product order" do
    a = PGA2.new(e1: 1, e12: 2)
    b = PGA2.new(e2: 3, e20: 4)

    assert PGA2.reverse(PGA2.gp(a, b)) ==
             PGA2.gp(PGA2.reverse(b), PGA2.reverse(a))
  end

  test "inner product vs grade" do
    e1 = PGA2.new(e1: 1)
    e12 = PGA2.new(e12: 1)

    result = PGA2.inner(e1, e12)

    assert PGA2.grade(result, 1) == result
  end

  test "inner product vector bivector" do
    e1 = PGA2.new(e1: 1)
    e12 = PGA2.new(e12: 1)

    assert PGA2.inner(e1, e12) ==
             PGA2.new(e2: 1)
  end

  test "zero?" do
    assert PGA2.zero?(PGA2.new())

    refute PGA2.zero?(PGA2.new(e1: 1))
    refute PGA2.zero?(PGA2.new(e1: 1, e12: 2))
  end

  test "grades" do
    assert PGA2.grades(PGA2.new()) == []

    assert PGA2.grades(PGA2.new(scalar: 1)) == [0]

    assert PGA2.grades(PGA2.new(e1: 1)) == [1]

    assert PGA2.grades(PGA2.new(e12: 1)) == [2]

    assert PGA2.grades(PGA2.new(e1: 1, e12: 1)) == [1, 2]
  end

  test "dual of basis blades" do
    assert PGA2.dual(PGA2.new(scalar: 1)) ==
             PGA2.new(e120: 1)

    assert PGA2.dual(PGA2.new(e1: 1)) ==
             PGA2.new(e20: 1)

    assert PGA2.dual(PGA2.new(e2: 1)) ==
             PGA2.new(e01: 1)

    assert PGA2.dual(PGA2.new(e0: 1)) ==
             PGA2.new(e12: 1)

    assert PGA2.dual(PGA2.new(e12: 1)) ==
             PGA2.new(e0: 1)

    assert PGA2.dual(PGA2.new(e10: 1)) ==
             PGA2.new(e2: -1)

    assert PGA2.dual(PGA2.new(e20: 1)) ==
             PGA2.new(e1: 1)

    assert PGA2.dual(PGA2.new(e120: 1)) ==
             PGA2.new(scalar: 1)
  end

  test "dual is linear" do
    a = PGA2.new(e1: 2, e12: 3)

    assert PGA2.dual(a) ==
             PGA2.add(
               PGA2.new(e20: 2),
               PGA2.new(e0: 3)
             )
  end

  test "dual preserves zero" do
    assert PGA2.dual(PGA2.new()) ==
             PGA2.new()
  end

  test "dual is involutive up to sign" do
    blades = [
      PGA2.new(scalar: 1),
      PGA2.new(e1: 1),
      PGA2.new(e2: 1),
      PGA2.new(e0: 1),
      PGA2.new(e12: 1),
      PGA2.new(e10: 1),
      PGA2.new(e20: 1),
      PGA2.new(e120: 1)
    ]

    for blade <- blades do
      double = PGA2.dual(PGA2.dual(blade))

      assert double == blade or
               double == PGA2.scale(-1, blade)
    end
  end

  test "dual distributes over addition" do
    a = PGA2.new(e1: 2, e12: 3)
    b = PGA2.new(e2: -1, e20: 4)

    assert PGA2.dual(PGA2.add(a, b)) ==
             PGA2.add(PGA2.dual(a), PGA2.dual(b))
  end

  test "wedge basis blades" do
    e1 = PGA2.new(e1: 1)
    e2 = PGA2.new(e2: 1)

    assert PGA2.wedge(e1, e2) ==
             PGA2.new(e12: 1)

    assert PGA2.wedge(e2, e1) ==
             PGA2.new(e12: -1)

    assert PGA2.wedge(e1, e1) ==
             PGA2.new()
  end

  test "wedge trivector" do
    e12 = PGA2.new(e12: 1)
    e0 = PGA2.new(e0: 1)

    assert PGA2.wedge(e12, e0) ==
             PGA2.new(e120: 1)
  end

  test "join is anti-commutative up to scale" do
    a = PGA3.new(e1: 1)
    b = PGA3.new(e2: 1)

    assert PGA3.join(a, b) ==
             PGA3.scale(-1, PGA3.join(b, a))
  end

  test "wedge is associative" do
    a = PGA2.new(e1: 1)
    b = PGA2.new(e2: 1)
    c = PGA2.new(e0: 1)

    assert PGA2.wedge(PGA2.wedge(a, b), c) ==
             PGA2.wedge(a, PGA2.wedge(b, c))
  end

  test "normalize" do
    assert PGA2.canonicalize(PGA2.new(e1: 5)) ==
             PGA2.new(e1: 1)

    assert PGA2.canonicalize(PGA2.new(e12: -3)) ==
             PGA2.new(e12: 1)

    assert PGA2.canonicalize(PGA2.new(scalar: 7)) ==
             PGA2.new(scalar: 1)
  end

  test "cannot normalize zero" do
    assert_raise ArgumentError, fn ->
      PGA2.normalize(PGA2.new())
    end
  end

  test "blade?" do
    assert PGA2.blade?(PGA2.new())

    assert PGA2.blade?(PGA2.new(e1: 1))
    assert PGA2.blade?(PGA2.new(e12: 1))
    assert PGA2.blade?(PGA2.new(e120: 1))

    refute PGA2.blade?(PGA2.new(e1: 1, e12: 1))
  end

  test "canonical normalize" do
    assert PGA2.canonicalize(PGA2.new(e1: -5)) ==
             PGA2.new(e1: 1)

    assert PGA2.canonicalize(PGA2.new(e12: -5)) ==
             PGA2.new(e12: 1)
  end

  test "canonicalize vector" do
    assert PGA2.canonicalize(PGA2.new(e1: -5, e2: 10)) ==
             PGA2.new(e1: 0.5, e2: -1)
  end

  test "blade detection" do
    assert PGA2.blade?(PGA2.new(e1: 1, e2: 2))
    assert PGA2.blade?(PGA2.new(e12: 1, e10: 2))

    refute PGA2.blade?(PGA2.new(e1: 1, e12: 2))
  end

  test "squared norm of scalar" do
    assert PGA2.squared_norm(PGA2.new(scalar: 5)) == 25
  end

  test "squared norm of Euclidean vector" do
    e1 = PGA2.new(e1: 1)

    assert PGA2.squared_norm(e1) == 1
  end

  test "squared norm of bivector" do
    e12 = PGA2.new(e12: 1)

    assert PGA2.squared_norm(e12) == 1
  end

  test "squared norm of null vector" do
    e0 = PGA2.new(e0: 1)

    assert PGA2.squared_norm(e0) == 0
  end

  test "squared norm uses reverse" do
    e12 = PGA2.new(e12: 1)

    assert PGA2.squared_norm(e12) == 1
  end

  test "norm" do
    assert PGA2.norm(PGA2.new(e1: 3)) == 3
    assert PGA2.norm(PGA2.new(e12: 4)) == 4
  end

  test "norm of null vector" do
    assert PGA2.norm(PGA2.new(e0: 1)) == 0
  end

  test "point constructor" do
    p = PGA3.point(2, 3, 4)

    assert PGA3.grade(p, 3) == p

    assert p ==
             PGA3.new(
               e123: 1,
               e032: 2,
               e013: 3,
               e021: 4
             )
  end

  test "join of two points gives a line" do
    a = PGA3.point(0, 0, 0)
    b = PGA3.point(1, 0, 0)

    line = PGA3.join(a, b)

    assert PGA3.blade?(line)
    assert PGA3.grade(line, 2) == line
  end

  test "meet of planes gives a line" do
    a = PGA3.new(e1: 1)
    b = PGA3.new(e2: 1)

    line = PGA3.meet(a, b)

    assert PGA3.blade?(line)
    assert PGA3.grade(line, 2) == line
  end

  test "point and plane grades" do
    p = PGA3.point(1, 2, 3)
    pl = PGA3.plane(1, 0, 0, -1)

    assert PGA3.grade(p, 3) == p
    assert PGA3.grade(pl, 1) == pl
  end

  test "point lies on plane" do
    p = PGA3.point(1, 2, 3)
    plane = PGA3.plane(1, 0, 0, -1)

    assert PGA3.zero?(PGA3.join(p, plane))
  end

  test "origin lies on coordinate planes" do
    p = PGA3.point(0, 0, 0)

    assert PGA3.zero?(PGA3.join(p, PGA3.plane(1, 0, 0, 0)))
    assert PGA3.zero?(PGA3.join(p, PGA3.plane(0, 1, 0, 0)))
    assert PGA3.zero?(PGA3.join(p, PGA3.plane(0, 0, 1, 0)))
  end

  test "join of two points creates a line" do
    a = PGA3.point(0, 0, 0)
    b = PGA3.point(1, 0, 0)

    line = PGA3.join(a, b)

    assert PGA3.grade(line, 2) == line
  end

  test "point not on plane" do
    p = PGA3.point(2, 0, 0)
    plane = PGA3.plane(1, 0, 0, -1)

    refute PGA3.zero?(PGA3.join(p, plane))
  end

  test "two planes meet in a line" do
    a = PGA3.plane(1, 0, 0, 0)
    b = PGA3.plane(0, 1, 0, 0)

    line = PGA3.meet(a, b)

    assert PGA3.grade(line, 2) == line
  end

  test "scaled points represent the same point" do
    p = PGA3.point(1, 2, 3)

    scaled =
      PGA3.scale(5, p)

    assert PGA3.normalize(p) ==
             PGA3.normalize(scaled)
  end

  test "scaled lines represent the same line" do
    a = PGA3.point(0, 0, 0)
    b = PGA3.point(1, 0, 0)

    line = PGA3.line(a, b)

    assert PGA3.canonicalize(line) ==
             PGA3.canonicalize(PGA3.scale(-3, line))
  end

  test "join of points creates a line" do
    a = PGA3.point(0, 0, 0)
    b = PGA3.point(1, 0, 0)

    line = PGA3.join(a, b)

    assert PGA3.grade(line, 2) == line
  end

  test "meet of two planes creates a line" do
    a = PGA3.plane(1, 0, 0, 0)
    b = PGA3.plane(0, 1, 0, 0)

    line = PGA3.meet(a, b)

    assert PGA3.grade(line, 2) == line
  end

  test "parallel planes do not intersect" do
    a = PGA3.plane(1, 0, 0, 0)
    b = PGA3.plane(1, 0, 0, -1)

    refute PGA3.intersects?(a, b)
  end

  test "planes intersect" do
    a = PGA3.plane(1, 0, 0, 0)
    b = PGA3.plane(0, 1, 0, 0)

    assert PGA3.intersects?(a, b)
  end

  test "line contains point" do
    a = PGA3.point(0, 0, 0)
    b = PGA3.point(1, 0, 0)
    p = PGA3.point(0.5, 0, 0)

    line = PGA3.line(a, b)

    assert PGA3.contains?(line, p)
  end

  test "debug join via undual" do
    ps = PGA3.dual(PGA3.new(scalar: 1))

    assert PGA3.join(ps, PGA3.point(1, 2, 3)) == PGA3.point(1, 2, 3)
    assert PGA3.join(PGA3.point(1, 2, 3), ps) == PGA3.point(1, 2, 3)
  end

  test "line does not contain point" do
    a = PGA3.point(0, 0, 0)
    b = PGA3.point(1, 0, 0)
    p = PGA3.point(0, 1, 0)

    line = PGA3.line(a, b)

    refute PGA3.contains?(line, p)
  end

  test "parallel planes are ideal intersection" do
    a = PGA3.plane(1, 0, 0, 0)
    b = PGA3.plane(1, 0, 0, -1)

    assert PGA3.ideal?(PGA3.meet(a, b))
  end

  test "intersecting planes are not ideal" do
    a = PGA3.plane(1, 0, 0, 0)
    b = PGA3.plane(0, 1, 0, 0)

    refute PGA3.ideal?(PGA3.meet(a, b))
  end

  test "same planes are coincident" do
    a = PGA3.plane(1, 0, 0, -1)
    b = PGA3.plane(2, 0, 0, -2)

    assert PGA3.coincident?(a, b)
  end

  test "same lines are coincident" do
    a = PGA3.point(0, 0, 0)
    b = PGA3.point(1, 0, 0)

    line1 = PGA3.line(a, b)
    line2 = PGA3.scale(5, line1)

    assert PGA3.coincident?(line1, line2)
  end

  test "different planes are not coincident" do
    a = PGA3.plane(1, 0, 0, -1)
    b = PGA3.plane(1, 0, 0, -2)

    refute PGA3.coincident?(a, b)
  end

  test "direction of x axis line" do
    a = PGA3.point(0, 0, 0)
    b = PGA3.point(1, 0, 0)

    dir = PGA3.ideal_direction(PGA3.line(a, b))

    assert PGA3.ideal?(dir)
  end

  test "parallel lines have same direction" do
    l1 =
      PGA3.line(
        PGA3.point(0, 0, 0),
        PGA3.point(1, 0, 0)
      )

    l2 =
      PGA3.line(
        PGA3.point(0, 1, 0),
        PGA3.point(1, 1, 0)
      )

    assert PGA3.coincident?(
             PGA3.ideal_direction(l1),
             PGA3.ideal_direction(l2)
           )
  end

  test "point distance" do
    a = PGA3.point(0, 0, 0)
    b = PGA3.point(3, 4, 0)

    assert PGA3.distance(a, b) == 5.0
  end

  test "coeffs" do
    a = PGA3.new(e1: 1, e2: 2, e23: 4, e230: 5)

    assert PGA3.coefficient(a, :e230) == 5
    assert PGA3.coefficient(a, :e320) == -5
    assert PGA3.coefficient(a, :e302) == 5
    assert PGA3.coefficient(a, :e23) == 4
    assert PGA3.coefficient(a, :e32) == -4
  end

  test "duals squared" do
    assert PGA3.dual(PGA3.dual(PGA3.new(e0: 1))) == PGA3.new(e0: -1)
    assert PGA3.dual(PGA3.dual(PGA3.new(e1: 1))) == PGA3.new(e1: -1)
    assert PGA3.dual(PGA3.dual(PGA3.new(e2: 1))) == PGA3.new(e2: -1)
    assert PGA3.dual(PGA3.dual(PGA3.new(e3: 1))) == PGA3.new(e3: -1)

    assert PGA3.dual(PGA3.dual(PGA3.new(e01: 1))) == PGA3.new(e01: 1)
    assert PGA3.dual(PGA3.dual(PGA3.new(e12: 1))) == PGA3.new(e12: 1)
    assert PGA3.dual(PGA3.dual(PGA3.new(e23: 1))) == PGA3.new(e23: 1)
    assert PGA3.dual(PGA3.dual(PGA3.new(e13: 1))) == PGA3.new(e13: 1)

    assert PGA3.dual(PGA3.new(e12: 1)) == PGA3.new(e30: 1)
    assert PGA3.dual(PGA3.new(e23: 1)) == PGA3.new(e10: 1)
    assert PGA3.dual(PGA3.new(e13: 1)) == PGA3.new(e20: -1)
  end

  test "scalar? tolerates floating point noise" do
    mv =
      PGA3.new(
        scalar: 1.0,
        e20: 1.0e-15
      )

    assert PGA3.scalar?(mv)
  end

  test "scalar? threshold" do
    assert PGA3.scalar?(PGA3.new(scalar: 1.0, e20: 1.0e-13))
    refute PGA3.scalar?(PGA3.new(scalar: 1.0, e20: 1.0e-9))
  end

  defp tuple_add(a, b) do
    Tuple.to_list(a)
    |> Enum.zip(Tuple.to_list(b))
    |> Enum.map(fn {x, y} -> x + y end)
    |> List.to_tuple()
  end

  defp random_mv do
    List.duplicate(0, 8)
    |> Enum.map(fn _ -> :rand.uniform(11) - 6 end)
    |> List.to_tuple()
  end
end
