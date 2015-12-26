use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :thoughtshare, Thoughtshare.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :thoughtshare, Thoughtshare.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "thoughtshare_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

  config :neo4j_sips, Neo4j,
    url: "http://localhost:8484",
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
