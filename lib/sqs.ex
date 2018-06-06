defmodule BtrzWebhooksEmitter.SQS do
  @moduledoc """
  Emit webhooks to SQS for the Betterez platform.
  """
  use GenServer
  require Logger

  @doc """
  Starts a new BtrzWebhooksEmitter process.
  """
  def start_link(params, opts \\ []) do
    GenServer.start_link(__MODULE__, Keyword.get(params, :queue_url, ""), opts)
  end

  def init(queue_url) do
    state = %{
      queue: queue_url
    }
    {:ok, state}
  end

  def handle_cast({:emit, message}, state) do
    case ExAws.SQS.send_message(
           state.queue,
           message
         )
         |> ExAws.request() do
      {:error, reason} ->
        Logger.error(reason)
      {:ok, _} ->
        Logger.debug("webhook emited! #{inspect(message)}")
    end

    {:noreply, state}
  end
end
