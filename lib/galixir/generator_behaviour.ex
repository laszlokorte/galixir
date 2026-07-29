defmodule Galixir.GeneratorBehaviour do
  @moduledoc """
  Defines the behaviour contract for Galixir code generators.

  A generator module is responsible for producing the implementation AST that is
  injected into generated algebra modules during compilation.

  Each generator receives a `Galixir.Meta` structure containing the information
  required to generate code for a specific algebra, such as its dimension,
  metric, basis blades, and precomputed lookup tables.

  Implementations must return a list of quoted expressions (`Macro.t()`) that can
  be inserted into the target module using `unquote_splicing/1`.

  This behaviour allows individual generators to be developed independently while
  providing a common interface for composing complete algebra implementations.
  """
  @type meta :: %Galixir.Meta{}
  @callback generate_implementation(arg :: meta) :: [Macro.t()]
end
