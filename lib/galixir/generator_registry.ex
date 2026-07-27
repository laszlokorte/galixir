defmodule Galixir.GeneratorRegistry do
  @moduledoc """
  Provides the registry of code generators used to build Galixir algebra modules.

  The registry defines the ordered collection of generator modules that contribute
  parts of the final generated algebra implementation.

  Each registered generator implements the `Galixir.GeneratorBehaviour` behaviour
  and produces a list of quoted expressions that are composed into the generated
  module during compilation.

  The order of generators is significant. Generators that provide foundational
  metadata or helper functions are executed before generators that depend on
  those definitions.

  Use `generators/0` to retrieve the complete list of registered generators.
  """
  @generators [
    Galixir.Generator.Header,
    Galixir.Generator.BasisNames,
    Galixir.Generator.Canonical,
    Galixir.Generator.Cofficients,
    Galixir.Generator.Dual,
    Galixir.Generator.GeometricProduct,
    Galixir.Generator.Grade,
    Galixir.Generator.InnerProduct,
    Galixir.Generator.Inspect,
    Galixir.Generator.Inverse,
    Galixir.Generator.LinearOps,
    Galixir.Generator.New,
    Galixir.Generator.Norm,
    Galixir.Generator.Predicates,
    Galixir.Generator.Reverse,
    Galixir.Generator.ScalarProduct,
    Galixir.Generator.WedgeProduct,
    Galixir.Generator.Sigil
  ]

  def generators do
    @generators
  end
end
