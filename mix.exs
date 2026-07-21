defmodule Galixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :galixir,
      version: "0.14.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/laszlokorte/galixir",
      deps: deps(),
      description: description(),
      package: package()
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

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
