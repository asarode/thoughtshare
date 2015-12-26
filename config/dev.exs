use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :thoughtshare, Thoughtshare.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  cache_static_lookup: false,
  check_origin: false,
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin"]]

# Watch static and templates for browser reloading.
config :thoughtshare, Thoughtshare.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development.
# Do not configure such in production as keeping
# and calculating stacktraces is usually expensive.
config :phoenix, :stacktrace_depth, 20

config :thoughtshare, Thoughtshare.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "thoughtshare_dev",
  hostname: "localhost",
  pool_size: 10

config :neo4j_sips, Neo4j,
  url: "http://localhost:7474",
  pool_size: 5,
  max_overflow: 2,
  timeout: 30,
  basic_auth: [username: System.get_env("NEO4J_USERNAME"), password: System.get_env("NEO4J_PASSWORD")]

config :joken, config_module: Guardian.JWT

config :guardian, Guardian,
      issuer: "MyApp",
      ttl: { 30, :days },
      verify_issuer: true,
      secret_key: "wd9v3wn3vdil0indjq2v0i",
      serializer: Thoughtshare.GuardianSerializer
