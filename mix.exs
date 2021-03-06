defmodule Rak.MixProject do
  use Mix.Project

  def project do
    [
      app: :rak,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: dialyzer(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: mod(Mix.env())
    ]
  end

  # Don't auto-start the application when MIX_ENV=test
  defp mod(:test), do: []
  defp mod(_), do: {Rak, []}

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 0.9.0-rc8", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5.1", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.8.1", only: [:dev, :test]}
    ]
  end

  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      lint: ["dialyzer", "credo", "test"]
    ]
  end

  defp dialyzer do
    [
      ignore_warnings: "dialyzer.ignore-warnings",
      flags: [
        # Warn for functions that only return by an exception.
        :error_handling,
        # Warn about behavior callbacks that drift from the published recommended interfaces.
        :no_behaviours,
        # Warn about invalid contracts.
        :no_contracts,
        # Warn for failing calls.
        :no_fail_call,
        # Warn for fun applications that will fail.
        :no_fun_app,
        # Warn for construction of improper lists.
        :no_improper_lists,
        # Warn for patterns that are unused or cannot match.
        :no_match,
        # Warn about calls to missing functions.
        :no_missing_calls,
        # Warn for violations of opacity of data types.
        :no_opaque,
        # Warn for functions that will never return a value.
        :no_return,
        # Warn about behaviors that have no -callback attributes for their callbacks.
        :no_undefined_callbacks,
        # Warn for unused functions.
        :no_unused,
        # Warn for possible race conditions
        :race_conditions,
        # Warn about underspecified functions
        # :underspecs,
        # Let warnings about unknown functions and types affect the exit status of the CLI version.
        :unknown,
        # Warn for function calls that ignore a structured return value
        :unmatched_returns
        # Warn about overspecified functions
        # :overspecs,
        # Warn when the specification is different than the success typing.
        # :specdiffs
      ]
    ]
  end
end
