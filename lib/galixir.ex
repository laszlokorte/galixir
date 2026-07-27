defmodule Galixir do
  @moduledoc """
  Galixir is a library for working with [Geometric Algebra (GA)](https://bivector.net) in Elixir.

  Geometric Algebra provides a unified mathematical language for describing
  geometric objects such as points, vectors, lines, planes, circles, spheres,
  and transformations. Instead of representing each object type separately,
  GA represents them as multivectors and uses algebraic operations to
  construct and manipulate them.

  Galixir provides tools for defining geometric algebras with arbitrary
  signatures and automatically generating the operations required to work
  with them.

  ## Geometric Algebras

  A geometric algebra is defined by its metric signature. For example:

     defmodule PGA3 do
       use Galixir.GeometricAlgebra,
         signature: {1, 1, 1, 0},
         bases: {1, 2, 3, 0}
     end

  This creates a projective geometric algebra for 3D Euclidean geometry
  containing basis vectors, multivectors, and operations such as:

    * geometric product (`gp/2`)
    * outer product (`wedge/2`)
    * inner product (`dot/2`)
    * reverse
    * dual
    * inverse
    * normalization

  ## Multivectors

  Multivectors are combinations of basis blades. For example:

      iex> import Galixir.Algebras.PGA3, only: [sigil_G: 2]
      iex> Galixir.Algebras.PGA3.new(e1: 1, e2: 2, e3: 3)
      ~G"1.0e1 + 2.0e2 + 3.0e3"

  A multivector can contain components of different grades:
      iex> import Galixir.Algebras.PGA3, only: [sigil_G: 2]
      iex> Galixir.Algebras.PGA3.new(e1: 1, e23: 2, scalar: 3)
      ~G"3.0 + 1.0e1 + 2.0e23"

  ## Geometry

  Higher-level geometry modules build on top of the generated algebra.

  For example, projective geometric algebra can represent:

    * points
    * directions
    * lines
    * planes
    * motors (rotations and translations)

  Conformal geometric algebra extends this further with representations for:

    * points
    * circles
    * spheres
    * intersections and joins

  ## Design Goals

  Galixir aims to provide:

    * a native Elixir implementation of geometric algebra
    * compile-time generation of efficient algebra operations
    * explicit and inspectable multivector representations
    * a foundation for computational geometry, robotics, graphics, and
      simulation

  ## Mathematical Background

  Geometric algebra is based on the Clifford algebra product:

      ab = a · b + a ∧ b

  In Elixir written as:

      iex> alias Galixir.Algebras.PGA2
      iex> {a, b} = {PGA2.vector(1, 2), PGA2.vector(2, 3)}
      iex> ab = PGA2.add(PGA2.inner(a, b), PGA2.wedge(a, b))
      iex> assert ab == PGA2.gp(a,b)

  where the geometric product combines the metric-dependent inner product
  with the antisymmetric outer product.

  Unlike traditional approaches that require different data structures for
  different geometric primitives, GA represents many geometric entities in
  a single algebraic framework.

  ## Further Reading

  More information about geometric algebra can be found in:

    * [bivector.net (Website)](https://bivector.net/)
    * [Why can't you multiply vectors? (conference talk by Freya Holmér)](https://www.youtube.com/watch?v=htYh-Tq7ZBI)
    * [Conformal Geometry, Euclidean Space and Geometric Algebra (paper by Chris Doran, Anthony Lasenby, Joan Lasenby)](https://arxiv.org/abs/cs/0203026)
    * [Projective Geometric Algebra as a Subalgebra of Conformal Geometric algebra (paper by Ales Navrat, Jaroslav Hrdina, Petr Vasik, Leo Dorst)](https://arxiv.org/abs/2002.05993)
    * [Geometric Algebra (paper by Eric Chisolm)](https://arxiv.org/abs/1205.5935)

  """
end
