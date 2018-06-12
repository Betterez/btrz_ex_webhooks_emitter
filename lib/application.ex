defmodule BtrzWebhooksEmitter.Application do
  @moduledoc """
  Application callback to start the service.
  """
  use Application

  @doc """
  Starts the BtrzWebhooksEmitter.
  """
  def start(_type, _args) do
    queue_url =
      System.get_env("SQS_QUEUE_URL") ||
        Application.get_env(:btrz_ex_webhooks_emitter, :queue_url)

    children = [
      %{
        id: :btrz_webhooks_emitter_sqs,
        start:
          {BtrzWebhooksEmitter.SQS, :start_link,
           [[queue_url: queue_url], [name: BtrzWebhooksEmitter.SQS]]}
      }
    ]

    options = [strategy: :one_for_one, name: __MODULE__]

    Supervisor.start_link(children, options)
  end
end
