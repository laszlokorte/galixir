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
