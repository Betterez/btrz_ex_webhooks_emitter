defmodule BtrzWebhooksEmitter.SQS do
  @moduledoc """
  Genserver for emitting events to the Betterez AWS SQS

  If there is no `SQS_QUEUE_URL`, the GenServer will be started with `:ignore` and the process will exit normally.
  """
  use GenServer
  require Logger

  @doc """
  Starts a new BtrzWebhooksEmitter process.
  """
  def start_link(params, opts \\ []) do
    GenServer.start_link(__MODULE__, Keyword.get(params, :queue_url), opts)
  end

  def init(nil) do
    Logger.error("missing queue url - ignoring BtrzWebhooksEmitter.SQS GenServer: exit normally")
    :ignore
  end

  def init(queue_url) do
    state = %{
      queue: queue_url
    }

    {:ok, state}
  end

  @doc """
  Sends async the message to AWS SQS.
  If something fails, it will just log the error.
  """
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
