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

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `galixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:galixir, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/galixir>.
