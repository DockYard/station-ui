defmodule StationUI.MixProject do
  use Mix.Project

  def project do
    [
      app: :station_ui,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env(), Application.get_env(:station_ui, :use_source_components, false)),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "StationUI",
      package: [
        organization: "dockyard",
        maintainers: [
          "DockYard"
        ],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/DockYard/station-ui"},
        files: ~w(lib sources mix.exs LICENSE.md README.md)
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test, true), do: ["lib", "sources/lib", "test/support"]
  defp elixirc_paths(:test, false), do: ["lib", "test/support"]
  defp elixirc_paths(_, true), do: ["lib", "sources/lib"]
  defp elixirc_paths(_, false), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gettext, "~> 0.20"},
      {:phoenix, "~> 1.7.11"},
      {:phoenix_live_view, "~> 0.20.7"},
      {:credo, "~> 1.7.0", only: [:dev, :test], runtime: false},
      {:tailwind_formatter, "~> 0.3.5", only: [:dev, :test], runtime: false}
    ]
  end
end
