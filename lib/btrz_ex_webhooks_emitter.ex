defmodule BtrzWebhooksEmitter do
  @moduledoc """
  Emit webhooks to SQS for the Betterez platform.
  """

  @doc """
  Sends a message to SQS
  """
  @spec emit(binary, map) :: :ok
  def emit(event_name, attrs) do
    with true <- service_started?(BtrzWebhooksEmitter.SQS),
         message <- build_message(event_name, attrs) do
      GenServer.cast(BtrzWebhooksEmitter.SQS, {:emit, message})
    end
  end

  @doc false
  defp service_started?(server) do
    case GenServer.whereis(server) do
      nil -> false
      _pid -> true
    end
  end

  @doc false
  @spec build_message(binary, map) :: binary
  defp build_message(event_name, attrs) do
    Poison.encode!(%{
      id: UUID.uuid4(),
      ts: DateTime.utc_now(),
      providerId: attrs["provider_id"],
      apiKey: attrs["api_key"],
      event: event_name,
      data: filter_fields(event_name, attrs["data"])
    })
  end

  @doc false
  defp filter_fields(event_name, data) do
    #IO.inspect BtrzWebhooksDeniedFields.get_fields()
    data
  end
end
