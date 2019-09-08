import Config

config :liveproxy, LiveproxyWeb.Endpoint,
  http: [:inet6, port: String.to_integer(System.get_env("PORT") || "4000"), compress: true]

config :geolix,
  databases: [
    %{
      id: :country,
      adapter: Geolix.Adapter.MMDB2,
      source: Path.join(:code.priv_dir(:liveproxy), "GeoLite2-Country.mmdb")
    }
  ]
