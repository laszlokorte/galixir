defmodule GeneratedDocsTest do
  use ExUnit.Case

  doctest Galixir.Algebras.PGA2, import: true
  doctest Galixir.Algebras.PGA3, import: true
  doctest Galixir.Algebras.CGA2, import: true
  doctest Galixir.Algebras.CGA3, import: true
  doctest Galixir.Algebras.Hyper1, import: true
  doctest Galixir.Algebras.Complex1, import: true
  doctest Galixir.Algebras.Dual1, import: true
  doctest Galixir.Algebras.Vector2, import: true
  doctest Galixir.Algebras.Vector3, import: true
end
