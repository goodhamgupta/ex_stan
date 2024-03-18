import Config

config :ex_stan,
  httpstan_url: "http://localhost:8080/v1"

config :logger, :console,
  format: "[$level] $message $metadata\n",
  metadata: [:error_code]
