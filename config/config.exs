use Mix.Config

config :ex_aws,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role]

config :btrz_ex_webhooks_emitter, queue_name: System.get_env("SQS_QUEUE_NAME")

if Mix.env() == :test do
  config :btrz_ex_webhooks_emitter,
    queue_name: System.get_env("SQS_QUEUE_NAME") || "000000000000/webhooks-test"

  config :btrz_ex_webhooks_emitter, :ex_aws_request_fn, fn _operation, aws_config ->
    case aws_config[:queue] do
      "http://wrong_url" -> {:error, {:http_error, 404, %{}}}
      _ -> {:ok, %{status_code: 200}}
    end
  end
end
