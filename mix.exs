defmodule Affirm.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [app: :affirm,
     version: @version,
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls],
     description: description(),
     package: package(),
     name: "Affirm",
     deps: deps()]
  end

  def application do
    [applications: [:logger, :httpoison, :poison]]
  end

  defp description do
    """
    Affirm API library for Elixir.
    """
  end

  defp package do
    [maintainers: ["RevZilla", "Tyler Cain", "Steve DeGele"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/revzilla/affirm"},
     files: ~w(lib mix.exs README.md)]
  end

  defp deps do
    [
      {:httpoison, "~> 0.12"},
      {:jason, "~> 1.0"},
      {:bypass, "~> 0.8", only: :test},
      {:excoveralls, "~> 0.7.4", only: :test},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
    ]
  end
end
