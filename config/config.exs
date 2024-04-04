import Config

config :logger, :console,
  format: "[$level] $message $metadata\n",
  metadata: [:error_code],
  colors: [
    enabled: true,
    info: :normal,
    warn: :yellow,
    error: :red,
    debug: :cyan,
    trace: :white
  ],
  pretty: true,
  structs: true
