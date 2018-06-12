defmodule BtrzWebhooksEmitter.MixProject do
  use Mix.Project

  @github_url "https://github.com/Betterez/btrz_ex_webhooks_emitter"
  @version "0.1.0"

  def project do
    [
      app: :btrz_ex_webhooks_emitter,
      version: @version,
      name: "BtrzWebhooksEmitter",
      description: "Webhooks emitter for the Elixir Betterez platform",
      source_url: @github_url,
      homepage_url: @github_url,
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      registered: [:btrz_ex_webhooks_emitter],
      mod: {BtrzWebhooksEmitter.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_aws, "~> 2.0"},
      {:ex_aws_sqs, "~> 2.0"},
      {:hackney, "~> 1.9"},
      {:sweet_xml, "~> 0.6"},
      {:poison, "~> 3.0"},
      {:uuid, "~> 1.1"},
      {:btrz_webhooks_denied_fields,
       git: "git://github.com/Betterez/btrz-webhooks-denied-fields.git"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:excoveralls, "~> 0.8", only: :test},
      {:junit_formatter, "~> 2.1", only: :test}
    ]
  end

  defp docs do
    [
      main: "BtrzWebhooksEmitter",
      source_ref: "v#{@version}",
      source_url: @github_url,
      extras: ["README.md"]
    ]
  end

  defp aliases do
    [
      test: ["coveralls"]
    ]
  end

  defp package do
    %{
      name: "btrz_ex_webhooks_emitter",
      licenses: ["MIT"],
      maintainers: ["Hernán García", "Pablo Brudnick"],
      links: %{"GitHub" => @github_url}
    }
  end
end
