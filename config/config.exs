use Mix.Config

config :ex_aws,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role]

config :btrz_ex_webhooks_emitter,
  queue_url: [{:system, "SQS_QUEUE_URL"}, :instance_role]

if Mix.env() == :test, do: import_config("test.exs")
