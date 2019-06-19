defmodule BtrzWebhooksEmitter.Application do
  @moduledoc """
  Application callback to start the service.
  """
  use Application

  @doc """
  Starts the BtrzWebhooksEmitter.
  """
  def start(_type, _args) do
    aws_config = [
      queue:
        System.get_env("SQS_QUEUE_URL") ||
          Application.get_env(:btrz_ex_webhooks_emitter, :queue_url),
      access_key_id: System.get_env("AWS_SERVICE_KEY"),
      secret_access_key: System.get_env("AWS_SERVICE_SECRET")
    ]

    children = [
      %{
        id: :btrz_webhooks_emitter_sqs,
        start:
          {BtrzWebhooksEmitter.SQS, :start_link, [aws_config, [name: :btrz_webhooks_emitter_sqs]]}
      }
    ]

    options = [strategy: :one_for_one, name: __MODULE__]

    Supervisor.start_link(children, options)
  end
end
