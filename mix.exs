defmodule EctoEncryptedId.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/a3kov/ecto_encrypted_id"

  def project do
    [
      app: :ecto_encrypted_id,
      version: @version,
      elixir: "~> 1.12",
      deps: deps(),
      source_url: @source_url,

      # Hex
      description: "Encrypted integer id fields for Ecto schemas",
      package: [
        licenses: ["MIT"],
        links: %{"GitHub" => @source_url}
      ],

      # Docs
      name: "EctoEncryptedId",
      docs: [
        main: "readme",
        extras: ["README.md"]
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
      {:ecto_sql, "~> 3.0"},
      {:base62, "~> 1.2"},
      {:stream_data, "~> 1.0", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end
end
