defmodule ExStan.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_stan,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:req, "~> 0.4.0"}
    ]
  end
end
