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
      queue: System.get_env("SQS_QUEUE_NAME") || Application.get_env(:btrz_ex_webhooks_emitter, :queue_name)
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
