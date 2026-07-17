# Galixir

[![galixir](https://img.shields.io/hexpm/v/galixir)](https://hex.pm/packages/galixir)

**!!!Still WIP/experimental!!!**

Geometric Algebra implementation in Elixir.

A concrete algebra can be generated via macro:

```ex
defmodule Galixir.PGA2 do
  # e1 squares to 1
  # e2 squares to 1
  # e3 squares to 0
  use Galixir.GeometricAlgebra, signature: {1, 1, 0}
end
```

## Installation

```elixir
def deps do
  [
    {:galixir, "~> 0.11.0"}
  ]
end
```

## Example

[This Livebook](./guides/example.livemd) shows an example of how to used 3D Projective Geometric Algebra (PGA3) to render a 3D scene as SVG.

![Preview Screenshot](./guides/preview.png)
