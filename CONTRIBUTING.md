# Contributing

## Development setup

Use Elixir 1.18 or newer within the 1.x series, with an Erlang/OTP release supported by your Elixir version. The minimum supported Elixir version is declared in `mix.exs`.

```sh
mix deps.get
mix compile --warnings-as-errors
```

## Validation

Run these checks before submitting a change:

```sh
mix format --check-formatted
mix test
mix credo --strict
mix docs --warnings-as-errors
```

Most public examples are doctests. When adding an algebra, register it in `test/generated_docs_test.exs` and add focused tests for its geometry helpers and degenerate inputs. Generated modules defined in tests need protocol consolidation disabled; the test environment is configured accordingly.

The Credo configuration keeps ordinary checks enabled, with scoped exceptions for macro templates: Credo otherwise counts generated function branches as complexity of the generator and cannot see documentation injected by `use`. Explicit algebra names are allowed in cross-algebra tests so that each operation's algebra remains visible.

## Numerical behavior

See the [numerical conventions](guides/introduction.md#numerical-conventions) before changing tolerances. Preserve current behavior unless the change intentionally revises the API, and test values on both sides of any threshold. Use approximate assertions for floating-point calculations when exact equality is not guaranteed.

## Release checks

```sh
mix hex.build --unpack
```

Inspect the resulting `galixir-VERSION/` directory. It must include `LICENSE`, the README, contributor instructions, and `guides/` (including images and the Livebook). To verify the actual distribution, run `mix deps.get` and `mix docs --warnings-as-errors` inside that unpacked directory, then remove it when finished. Do not commit generated docs or package artifacts.
