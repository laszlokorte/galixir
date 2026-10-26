# Introduction

Galixir generates geometric algebras in Elixir. Use a ready-made algebra for common geometry tasks, or define a new one with `Galixir.GeometricAlgebra` when you need a different metric.

## Getting started

Add Galixir to your `mix.exs` dependencies (see the [installation instructions](../README.md#installation)), then use a concrete algebra such as `Galixir.Algebras.PGA3`:

```elixir
alias Galixir.Algebras.PGA3

origin = PGA3.origin()
point = PGA3.point(1, 2, 3)
PGA3.point_coordinates(point)
# => {1.0, 2.0, 3.0}

motor = PGA3.translator(1, 0, 0)
origin |> PGA3.transform(motor) |> PGA3.point_coordinates()
# => {1.0, 0.0, 0.0}
```

`PGA3` uses dual 3D projective geometry: points are grade-3 blades, lines are grade-2 blades, and planes are grade-1 blades. `point/3` creates a finite point, while `ideal_point/3` creates a direction at infinity; `point_coordinates/1` only accepts finite points. `vector/3` creates a Euclidean vector, not an ideal point. The generated algebra also supplies operations such as `gp/2` (geometric product), `wedge/2` (outer product), and `normalize!/1`.

`PGA2` and `PGA4` provide projective geometry in other dimensions; `CGA2` and `CGA3` provide conformal algebras. `Vector2` and `Vector3` provide Euclidean vector operations. Higher-level helpers vary by module, so consult each module's API before switching algebras.

For a 3D scene with interactive camera controls, open the [PGA3 Livebook](./example.livemd) in Livebook.

## Numerical conventions

Multivector coefficients use floating-point arithmetic in keyword constructors and
most operations. Tuple construction preserves its elements as supplied. Small
rounding errors are expected; use approximate comparisons for computed coordinates
rather than assuming exact equality.

There is no single global zero test:

- `epsilon/0` defaults to `1.0e-10` and is configured with the `:epsilon` option
  when defining an algebra. It must be a non-negative float.
- `above_epsilon?/1` and its guard test `abs(value) > epsilon()`. The two-argument
  forms allow an explicit threshold.
- `normalize/1` compares the absolute **squared norm** against epsilon, not the
  norm or each coefficient. With the default epsilon, the norm cutoff is
  approximately `1.0e-5` (subject to floating-point rounding at the boundary).
  `normalize!/1` raises instead of returning `:error`.
- `inverse/1` requires a scalar reverse product and a scalar denominator whose
  absolute value exceeds epsilon. This reverse-based algorithm does not cover
  every invertible mixed-grade multivector.
- `scalar?/1` treats non-scalar coefficients of magnitude at most `1.0e-12` as
  zero, independently of the configured epsilon. `inverse/1` uses this check.
- `zero?/1` and its guard require exact zero coefficients. Grade-homogeneity
  checks are also exact; they do not discard small coefficients.
- `canonicalize/1` checks the largest absolute coefficient against epsilon.
  Its blade check means grade-homogeneous, not necessarily decomposable.
- Inspect formatting may display sufficiently small nonzero coefficients as `ε`.
  This is a display convention, not a lossless serialization format.

Geometry helpers may apply thresholds to derived quantities, such as homogeneous
weights or squared radii. Consult each function's documentation before rescaling
inputs or changing epsilon. These conventions document existing behavior rather
than imposing a uniform tolerance on mathematically different quantities.
