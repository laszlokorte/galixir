# Algebra model refactoring plan

## Goal

Extract the genuinely shared parts of each algebra family into its model `use` macro, following the existing `Vector2`/`Vector3`/`Vector4` pattern. `PGA2`, `PGA3`, and `PGA4` should use `Galixir.Algebras.Models.PGA`; `CGA2` and `CGA3` should use `Galixir.Algebras.Models.CGA`. Each resulting module must expose geometry that is meaningful in its own dimension, with accurate generated documentation and passing doctests.

Use the working `main` branch as the behavioral reference for existing `PGA2`, `PGA3`, and `CGA2` functionality. Preserve the uncommitted changes to `cga2.ex` and `models/cga.ex` on `wip`; inspect their diff before editing and build on that work rather than overwriting it. `PGA4` and `CGA3` do not have the same established higher-level API as the older modules, so define and test their supported functionality deliberately rather than assuming all lower-dimensional helpers apply.

## File scope

During the refactoring, modify **only files under `lib/galixir/algebras/`**. Do not edit tests, other library files, configuration, or guides. This `PLAN.md` is the separately requested planning document, not an implementation file to change as part of the refactoring. Existing tests and doctests may be run without changing their files; if additional coverage requires edits outside the allowed directory, report the gap rather than making those edits.

## Design rules

- The model macros generate the metric, basis, and operations whose definitions are valid across the supported dimensions. Generate dimension-dependent signatures, blade names and signs, coordinate tuples, and formulas from the selected dimensions rather than embedding 2D or 3D literals in shared code.
- Model geometry explicitly. In dual PGA, a 2D line is a grade-1 object and a 2D point is grade-2; in 3D, a plane is grade-1, a line is grade-2, and a point is grade-3. Determine the corresponding 4D objects and grades before exposing constructors or helpers there. Do not treat distinct geometric objects as interchangeable merely because they share a name in another dimension.
- Keep fundamentally dimension-specific definitions in `pga2.ex`, `pga3.ex`, `pga4.ex`, `cga2.ex`, or `cga3.ex` as needed. For example, 2D and 3D line/plane helpers or rotation APIs need not be forced into one universal implementation. Small per-dimension modules are a goal, not a constraint that overrides correct geometry.
- Generate `@moduledoc`, `@doc`, and doctest examples alongside the code they describe. Adapt every generated example to the actual dimension: algebra signature, basis, object grades, constructor arities, coordinate counts, and expected values. Keep docs and doctests for dimension-specific functions with those functions in their concrete modules. Do not emit a function or an example for a dimension in which it does not make sense.
- Preserve existing public functions, behavior, and mathematical conventions where applicable, including homogeneous scaling, blade orientation/signs, error handling, and transformation conventions. Where an API truly cannot be shared across dimensions, retain the established per-dimension API instead of silently changing it.

## Steps

1. **Inventory and baseline.** Compare the `main` implementations of `PGA2`, `PGA3`, and `CGA2` with `wip`. Record their public functions, doctests, basis conventions, and dimension-specific behavior. Inspect the current uncommitted CGA diff. Run the focused tests/doctests to identify existing failures before changing code; keep pre-existing failures separate from regressions.
2. **Finish the PGA model.** Replace the currently 3D-specific parts of `models/pga.ex` with dimension-aware generation for common PGA operations. Generate points, coordinates, directions, translations, etc. only where their definitions can be made correct for that dimension. Retain the genuinely different line, plane, rotor, motor, or other helpers in the appropriate concrete module. Keep the `PGA2/3/4` declarations readable.
3. **Finish the CGA model.** Extend `models/cga.ex` beyond the generated metric and basis with operations genuinely shared by `CGA2` and `CGA3`, such as conformal basis, point embedding, and coordinate extraction where equivalent. Move suitable `CGA2` code into the macro without losing its behavior. Define `CGA3` geometry and its supported API intentionally; leave dimension-specific constructions and classification helpers local where appropriate.
4. **Generate and review documentation.** Build dimension-aware module docs and function docs within each model macro, including executable doctests for every generated dimension. Check that local docs describe only functions actually present in that concrete module and that examples exercise the correct arities, grades, blade signs, and outputs.
5. **Validate incrementally.** Use existing tests and doctests to check shared behavior and each dimension's distinct objects and operations, including constructors, coordinate round trips, incidence/joins/meets where applicable, transformations, and invalid or ideal cases. Check generated documentation for every dimension; note that the existing `test/generated_docs_test.exs` does not register `PGA4`, so its doctests need a read-only way to run or must be reported as unverified. Run focused doctests and tests for PGA and CGA, then `mix format --check-formatted` and the full `mix test` suite. Investigate any difference from `main` rather than changing expected results just to make tests pass. Do not edit test files to make them pass.

## Done when

- `PGA2/3/4` and `CGA2/3` use their respective model macros without inheriting incorrect geometry or 2D/3D-only APIs.
- Existing `main` behavior for supported PGA2, PGA3, and CGA2 operations is preserved, apart from deliberate, documented changes.
- Generated docs and doctests are correct and executable for every supported dimension; no hard-coded 3D example appears in a different-dimensional module.
- Focused and full test suites pass, or remaining pre-existing failures are clearly identified.
