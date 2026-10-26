defmodule PGA4Test do
  use ExUnit.Case, async: true

  alias Galixir.Algebras.PGA4

  test "hyperplanes contain exactly the expected points" do
    plane = PGA4.hyperplane(0, 0, 0, 1, -4)
    assert PGA4.grade(plane) == 1
    assert PGA4.incident?(plane, PGA4.point(1, 2, 3, 4))
    refute PGA4.incident?(plane, PGA4.point(1, 2, 3, 5))
  end

  test "line and plane joins have the expected grades and incidence" do
    a = PGA4.origin()
    b = PGA4.point(1, 0, 0, 0)
    c = PGA4.point(0, 1, 0, 0)
    line = PGA4.line(a, b)
    plane = PGA4.plane(a, b, c)

    assert PGA4.grade(line) == 3
    assert PGA4.grade(plane) == 2
    assert PGA4.incident?(line, a)
    assert PGA4.incident?(line, b)
    assert PGA4.incident?(plane, c)
    refute PGA4.incident?(plane, PGA4.point(0, 0, 1, 0))
  end

  test "dependent points give zero joins" do
    assert PGA4.zero?(PGA4.line(PGA4.origin(), PGA4.origin()))

    assert PGA4.zero?(PGA4.plane(PGA4.origin(), PGA4.point(1, 0, 0, 0), PGA4.point(2, 0, 0, 0)))
  end
end
