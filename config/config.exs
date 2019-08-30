# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :liveproxy, LiveproxyWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Q4GbsRBzoRF6ak8GJlQWAIrJh94EApCE+IYcUV7DMvhdwfD4rXIdzH6y085ex1JE",
  render_errors: [view: LiveproxyWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Liveproxy.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "vULXjJrnWIDuOO/VT3GWjh4UgVouHEuO"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
