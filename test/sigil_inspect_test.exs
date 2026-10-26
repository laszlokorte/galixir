defmodule SigilInspectTest do
  use ExUnit.Case

  import Galixir.Algebras.PGA3

  test "parser rejects incomplete expressions and missing operators" do
    for expression <- ["", " ", "+", "-", "1+", "e1-", "1 + ", "1 2", "e1 e2", "1++2", "1+-2"] do
      assert_raise ArgumentError, fn -> parse(expression) end
    end
  end

  test "parser accepts signs, explicit products, aliases, and surrounding spaces" do
    assert parse(" +2*e1 - 0.5e21 + ε ") ==
             new(e1: 2, e12: 0.5, scalar: epsilon())
  end

  test "sigils reject malformed input at expansion time" do
    assert_raise ArgumentError, fn ->
      Code.eval_quoted(
        quote do
          import Galixir.Algebras.PGA3, only: [sigil_G: 2]
          ~G[1+]
        end
      )
    end
  end

  test "inspect matches sigil" do
    cases = [
      {~G[0.0], "~G[0.0]"},
      {~G[1], "~G[1.0]"},
      {~G[-1], "~G[-1.0]"},
      {~G[1.0], "~G[1.0]"},
      {~G[-1.0], "~G[-1.0]"},
      {~G[1.0e1], "~G[1.0e1]"},
      {~G[-1.0e1], "~G[-1.0e1]"},
      {~G[1.0e2], "~G[1.0e2]"},
      {~G[-1.0e2], "~G[-1.0e2]"},
      {~G[1.0e3], "~G[1.0e3]"},
      {~G[-1.0e3], "~G[-1.0e3]"},
      {~G[2e1], "~G[2.0e1]"},
      {~G[-2e1], "~G[-2.0e1]"},
      {~G[3e2], "~G[3.0e2]"},
      {~G[-3e2], "~G[-3.0e2]"},
      {~G[1 + 1.0e1], "~G[1.0 + 1.0e1]"},
      {~G[1 - 1.0e1], "~G[1.0 - 1.0e1]"},
      {~G[-1 + 1.0e1], "~G[-1.0 + 1.0e1]"},
      {~G[-1 - 1.0e1], "~G[-1.0 - 1.0e1]"},
      {~G[1 + 2e1], "~G[1.0 + 2.0e1]"},
      {~G[1 - 2e1], "~G[1.0 - 2.0e1]"},
      {~G[-1 + 2e1], "~G[-1.0 + 2.0e1]"},
      {~G[-1 - 2e1], "~G[-1.0 - 2.0e1]"},
      {~G[1.0e1 + 1.0e2], "~G[1.0e1 + 1.0e2]"},
      {~G[1.0e1 - 1.0e2], "~G[1.0e1 - 1.0e2]"},
      {~G[-1.0e1 + 1.0e2], "~G[-1.0e1 + 1.0e2]"},
      {~G[-1.0e1 - 1.0e2], "~G[-1.0e1 - 1.0e2]"},
      {~G[2e1 + 3e2], "~G[2.0e1 + 3.0e2]"},
      {~G[2e1 - 3e2], "~G[2.0e1 - 3.0e2]"},
      {~G[-2e1 + 3e2], "~G[-2.0e1 + 3.0e2]"},
      {~G[-2e1 - 3e2], "~G[-2.0e1 - 3.0e2]"},
      {~G[1.5e1], "~G[1.5e1]"},
      {~G[-1.5e1], "~G[-1.5e1]"},
      {~G[0.5e1], "~G[0.5e1]"},
      {~G[1 + 2e1 + 3e2], "~G[1.0 + 2.0e1 + 3.0e2]"},
      {~G[1 - 2e1 + 3e2], "~G[1.0 - 2.0e1 + 3.0e2]"},
      {~G[-1 + 2e1 - 3e2], "~G[-1.0 + 2.0e1 - 3.0e2]"},
      {~G[1.0e1 + 1.0e2 + 1.0e3], "~G[1.0e1 + 1.0e2 + 1.0e3]"},
      {~G[-1.0e1 - 1.0e2 - 1.0e3], "~G[-1.0e1 - 1.0e2 - 1.0e3]"},
      {~G[2e1 - 3e2 + 4e3], "~G[2.0e1 - 3.0e2 + 4.0e3]"},
      {~G[1.0e1 + 0.0e2], "~G[1.0e1]"},
      {~G[0.0 + 1.0e1], "~G[1.0e1]"},
      {~G[ε + εe1], "~G[ε + εe1]"},
      {~G[-ε - εe1], "~G[-ε - εe1]"},
      {~G[-ε + εe1], "~G[-ε + εe1]"},
      {~G[ε], "~G[ε]"},
      {~G[-ε], "~G[-ε]"}
    ]

    for {sigil, expected} <- cases do
      assert inspect(sigil) == expected
    end
  end

  test "inspect matches sigil with short ones" do
    cases = [
      {~G[0.0], "~G[0.0]"},
      {~G[1], "~G[1.0]"},
      {~G[-1], "~G[-1.0]"},
      {~G[1.0], "~G[1.0]"},
      {~G[-1.0], "~G[-1.0]"},
      {~G[e1], "~G[e1]"},
      {~G[-e1], "~G[-e1]"},
      {~G[e2], "~G[e2]"},
      {~G[-e2], "~G[-e2]"},
      {~G[e3], "~G[e3]"},
      {~G[-e3], "~G[-e3]"},
      {~G[2e1], "~G[2.0e1]"},
      {~G[-2e1], "~G[-2.0e1]"},
      {~G[3e2], "~G[3.0e2]"},
      {~G[-3e2], "~G[-3.0e2]"},
      {~G[1 + e1], "~G[1.0 + e1]"},
      {~G[1 - e1], "~G[1.0 - e1]"},
      {~G[-1 + e1], "~G[-1.0 + e1]"},
      {~G[-1 - e1], "~G[-1.0 - e1]"},
      {~G[1 + 2e1], "~G[1.0 + 2.0e1]"},
      {~G[1 - 2e1], "~G[1.0 - 2.0e1]"},
      {~G[-1 + 2e1], "~G[-1.0 + 2.0e1]"},
      {~G[-1 - 2e1], "~G[-1.0 - 2.0e1]"},
      {~G[e1 + e2], "~G[e1 + e2]"},
      {~G[e1 - e2], "~G[e1 - e2]"},
      {~G[-e1 + e2], "~G[-e1 + e2]"},
      {~G[-e1 - e2], "~G[-e1 - e2]"},
      {~G[2e1 + 3e2], "~G[2.0e1 + 3.0e2]"},
      {~G[2e1 - 3e2], "~G[2.0e1 - 3.0e2]"},
      {~G[-2e1 + 3e2], "~G[-2.0e1 + 3.0e2]"},
      {~G[-2e1 - 3e2], "~G[-2.0e1 - 3.0e2]"},
      {~G[1.5e1], "~G[1.5e1]"},
      {~G[-1.5e1], "~G[-1.5e1]"},
      {~G[0.5e1], "~G[0.5e1]"},
      {~G[1 + 2e1 + 3e2], "~G[1.0 + 2.0e1 + 3.0e2]"},
      {~G[1 - 2e1 + 3e2], "~G[1.0 - 2.0e1 + 3.0e2]"},
      {~G[-1 + 2e1 - 3e2], "~G[-1.0 + 2.0e1 - 3.0e2]"},
      {~G[e1 + e2 + e3], "~G[e1 + e2 + e3]"},
      {~G[-e1 - e2 - e3], "~G[-e1 - e2 - e3]"},
      {~G[2e1 - 3e2 + 4e3], "~G[2.0e1 - 3.0e2 + 4.0e3]"},
      {~G[e1 + 0.0e2], "~G[e1]"},
      {~G[0.0 + e1], "~G[e1]"}
    ]

    for {sigil, expected} <- cases do
      assert inspect(sigil, custom_options: [short_ones: true]) == expected
    end
  end

  test "inspect matches sigil with all blades" do
    cases = [
      {~G[0.0],
       "~G[0.0 + 0.0e1 + 0.0e2 + 0.0e12 + 0.0e3 + 0.0e13 + 0.0e23 + 0.0e123 + 0.0e0 + 0.0e10 + 0.0e20 + 0.0e120 + 0.0e30 + 0.0e130 + 0.0e230 + 0.0e1230]"},
      {~G[1],
       "~G[1.0 + 0.0e1 + 0.0e2 + 0.0e12 + 0.0e3 + 0.0e13 + 0.0e23 + 0.0e123 + 0.0e0 + 0.0e10 + 0.0e20 + 0.0e120 + 0.0e30 + 0.0e130 + 0.0e230 + 0.0e1230]"},
      {~G[2e1 - 1],
       "~G[-1.0 + 2.0e1 + 0.0e2 + 0.0e12 + 0.0e3 + 0.0e13 + 0.0e23 + 0.0e123 + 0.0e0 + 0.0e10 + 0.0e20 + 0.0e120 + 0.0e30 + 0.0e130 + 0.0e230 + 0.0e1230]"},
      {~G[-2e1 + e2],
       "~G[0.0 - 2.0e1 + 1.0e2 + 0.0e12 + 0.0e3 + 0.0e13 + 0.0e23 + 0.0e123 + 0.0e0 + 0.0e10 + 0.0e20 + 0.0e120 + 0.0e30 + 0.0e130 + 0.0e230 + 0.0e1230]"},
      {~G[3e2 + 1],
       "~G[1.0 + 0.0e1 + 3.0e2 + 0.0e12 + 0.0e3 + 0.0e13 + 0.0e23 + 0.0e123 + 0.0e0 + 0.0e10 + 0.0e20 + 0.0e120 + 0.0e30 + 0.0e130 + 0.0e230 + 0.0e1230]"}
    ]

    for {sigil, expected} <- cases do
      assert inspect(sigil, custom_options: [all_blades: true]) == expected
    end
  end
end
