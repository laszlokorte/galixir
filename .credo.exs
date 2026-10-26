%{
  configs: [
    %{
      name: "default",
      strict: true,
      files: %{included: ["lib/", "test/", "mix.exs"], excluded: []},
      checks: %{
        extra: [
          # Template branches belong to many generated functions, not one large function.
          {Credo.Check.Refactor.CyclomaticComplexity,
           max_complexity: 12, files: [excluded: [~r"lib/galixir/generator/"]]},
          {Credo.Check.Refactor.Nesting,
           max_nesting: 4,
           files: [excluded: [~r"lib/galixir/generator/", ~r"lib/galixir/algebras/models/"]]},
          {Credo.Check.Refactor.LongQuoteBlocks,
           files: [excluded: [~r"lib/galixir/generator/", ~r"lib/galixir/algebras/models/"]]},
          # These modules receive their module docs from the model's __using__/1 macro.
          {Credo.Check.Readability.ModuleDoc,
           files: [excluded: [~r"lib/galixir/algebras/(cga[23]|pga[234]|vector[234])\.ex$"]]},
          # Cross-algebra tests intentionally keep the algebra explicit at each call site.
          {Credo.Check.Design.AliasUsage,
           if_nested_deeper_than: 2, files: [excluded: [~r"test/"]]}
        ]
      }
    }
  ]
}
