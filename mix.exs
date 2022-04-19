defmodule Liquex.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :liquex,
      version: "0.7.2",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      name: "liquex",
      source_url: "https://github.com/markglenn/liquex",
      homepage_url: "https://github.com/markglenn/liquex",
      docs: [main: "Liquex", extras: ["README.md"]],
      aliases: aliases(),
      package: [
        maintainers: ["markglenn@gmail.com"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/markglenn/liquex"}
      ]
    ]
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
      {:nimble_parsec, "~> 1.1"},
      {:timex, "~> 3.6"},
      {:date_time_parser, "~> 1.1"},
      {:html_entities, "~> 0.5.1"},
      {:html_sanitize_ex, "~> 1.3.0"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:jason, "~> 1.0", only: [:dev, :test], runtime: false},
      {:hrx, "~> 0.1.0", only: [:test], runtime: false}
    ]
  end

  defp aliases do
    [
      lint: ["format --check-formatted", "credo --strict", "dialyzer"]
    ]
  end

  defp description do
    """
    Liquid template parser for Elixir. 100% compatibility with the Liquid gem for Ruby.
    """
  end
end
