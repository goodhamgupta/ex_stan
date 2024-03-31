defmodule ExStan.MixProject do
  use Mix.Project

  @version "0.1.0"
  @repo_url "https://github.com/nx-probability/ex_stan/"

  def project do
    [
      app: :ex_stan,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      package: package(),
      description:
        "ExStan, a Elixir Interface to Stan, a platform for statistical modelling and high-performance computation.",

      # Docs
      name: "ExStan",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:nx, "~> 0.7.1"},
      {:explorer, "~> 0.8.0", optional: true},
      {:jason, "~> 1.4"},
      {:req, "~> 0.4.0"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["ISC"],
      links: %{"GitHub" => @repo_url}
    ]
  end

  defp docs do
    [
      main: "ExStan",
      source_ref: "v#{@version}",
      source_url: @repo_url
    ]
  end
end
