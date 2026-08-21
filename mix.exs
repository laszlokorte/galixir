defmodule Galixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :galixir,
      version: "0.31.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/laszlokorte/galixir",
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  defp package() do
    %{
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/laszlokorte/galixir"}
    }
  end

  defp description() do
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
      groups_for_modules: [
        Algebras: [
          ~r/^Galixir\.Algebras/
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
