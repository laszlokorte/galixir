defmodule Galixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :galixir,
      name: "Galixir",
      version: "0.35.0-rc1",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      source_url: "https://github.com/laszlokorte/galixir",
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  defp package do
    %{
      licenses: ["Apache-2.0"],
      files: ~w(lib guides .formatter.exs .credo.exs mix.exs README.md CONTRIBUTING.md LICENSE),
      links: %{"GitHub" => "https://github.com/laszlokorte/galixir"}
    }
  end

  defp description do
    "Elixir Macros implementing Geometric Algebras"
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "CONTRIBUTING.md",
        "guides/introduction.md",
        "guides/example.livemd"
      ],
      assets: %{
        "guides" => "guides"
      },
      groups_for_extras: [
        Introduction: ~r".*introduction",
        Livebooks: ~r".*livemd"
      ],
      groups_for_modules: [
        Algebras: [
          ~r/^Galixir\.Algebras.(?!Models)/
        ],
        Models: [
          ~r/^Galixir\.Algebras.Models/
        ],
        Generators: [
          Galixir.GeometricAlgebra,
          Galixir.Blade,
          Galixir.Chain,
          Galixir.GeneratorBehaviour,
          Galixir.GeneratorRegistry,
          Galixir.Meta,
          Galixir.Table,
          ~r/^Galixir\.Generator/
        ]
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
