defmodule SmartWebsocketClient.Mixfile do
  use Mix.Project

  def project do
    [app: :smart_websocket_client,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     elixirc_paths: compile_paths(Mix.env),
     elixirc_options: [warnings_as_errors: true],
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :poolboy, :cowboy]]
  end

  defp compile_paths(:test),
    do: ["lib", "test/helper"]
  defp compile_paths(_),
    do: ["lib"]

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:socket, "~> 0.3"},
     {:poolboy, "~> 1.5"},
     {:poison, "~> 3.0"},
     {:cowboy, "~> 1.0"},
     {:ex_doc, "~> 0.14", only: :dev}]
  end
end
