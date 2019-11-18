defmodule NodeMonitor.MixProject do
  use Mix.Project

  @description """
  Simple Node monitor library
  """

  def project do
    [
      app: :node_monitor,
      version: "0.1.0",
      elixir: "~> 1.9",
      description: @description,
      start_permanent: Mix.env() == :prod,
      docs: docs(),
      deps: deps(),
      package: package(),
      dialyzer: dialyzer(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {NodeMonitor.Application, []}
    ]
  end

  defp deps do
    [
      {:aten, "~> 0.5.2"},
      # Code Quality
      {:credo, "~> 1.1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      # Document
      {:earmark, "~> 1.4.2", only: :dev, runtime: false},
      {:ex_doc, "~> 0.21.1", only: :dev, runtime: false},
      # Test
      {:excoveralls, "~> 0.12", only: :test},
      {:local_cluster, "~> 1.1", only: [:test]}
    ]
  end

  defp docs do
    [
      formatters: ["html"]
    ]
  end

  defp package do
    [
      maintainers: ["Eishun Kondoh"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/shun159/node_monitor"},
      files: ~w(.formatter.exs mix.exs README.md lib)
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:ex_unit],
      flags: [:error_handling, :underspecs, :unmatched_returns],
      ignore_warnings: "dialyzer_ignore.exs"
    ]
  end
end
