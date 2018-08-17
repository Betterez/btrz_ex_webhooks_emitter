defmodule BtrzWebhooksEmitter do
  @moduledoc """
  BtrzWebhooksEmitter emits webhooks to SQS for the Betterez platform.

  This module has the API to send messages asynchrounously to the `BtrzWebhooksEmitter.SQS`.

  You will have to set these ENV vars:

  * AWS_SERVICE_KEY
  * AWS_SERVICE_SECRET
  * SQS_QUEUE_URL

  You can set `SQS_QUEUE_URL` in your config:
  ```elixir
  config :btrz_ex_webhooks_emitter, queue_url: "id/name"
  ```

  If one of them is missing the messages will be ignored.

  ## How to use

  You have to send a map with the following required (string) keys:
   * "provider_id"
   * "api_key"
   * "data"

  Optional keys:
   * "url"

  ```elixir
  message = %{
    "provider_id" => "123",
    "api_key" => "PROVIDER_PUBLIC_KEY",
    "data" => %{"foo" => "bar"}
  }
  BtrzWebhooksEmitter.emit("transaction.created", message)
  ```
  """
  require Logger

  @doc """
  Builds and sends messages asynchrounously to the BtrzWebhooksEmitter.SQS
  """
  @spec emit(binary, map) :: :ok
  def emit(event_name, attrs) do
    with :ok <- validate_fields(event_name, attrs),
         true <- service_started?(BtrzWebhooksEmitter.SQS),
         message <- build_message(event_name, attrs) do
      GenServer.cast(BtrzWebhooksEmitter.SQS, {:emit, message})
    end
  end

  @doc false
  @spec validate_fields(binary, map) :: :ok | :error
  defp validate_fields(event_name, _attrs) when not is_binary(event_name) do
    Logger.error("event_name is missing")
    :error
  end

  defp validate_fields(_event_name, attrs) do
    cond do
      not is_binary(attrs["provider_id"]) ->
        Logger.error("provider_id is missing")
        :error

      not is_binary(attrs["api_key"]) ->
        Logger.error("api_key is missing")
        :error

      true ->
        :ok
    end
  end

  @doc false
  @spec service_started?(GenServer.server()) :: boolean
  defp service_started?(server) do
    case GenServer.whereis(server) do
      nil -> false
      _pid -> true
    end
  end

  @doc """
  Returns the message json encoded.
  """
  @spec build_message(binary, map) :: binary
  def build_message(event_name, attrs) do
    %{
      id: UUID.uuid4(),
      ts: DateTime.utc_now(),
      providerId: attrs["provider_id"],
      apiKey: attrs["api_key"],
      event: event_name,
      data: filter_fields(event_name, attrs["data"])
    }
    |> maybe_put_url(attrs)
    |> Poison.encode!()
  end

  @doc false
  defp maybe_put_url(message, %{"url" => url}) do
    Map.put_new(message, "url", url)
  end

  defp maybe_put_url(message, _), do: message

  @doc false
  @spec filter_fields(binary, map | any) :: map | any
  defp filter_fields(event_name, data) when is_map(data) do
    denied_fields = get_denied_fields(event_name)
    denied_found = Map.take(data, denied_fields)
    Map.drop(data, Map.keys(denied_found))
  end

  defp filter_fields(_, data), do: data

  @doc false
  @spec get_denied_fields(binary) :: list
  defp get_denied_fields(event_name) do
    all_denied_fields = BtrzWebhooksDeniedFields.get_fields()
    wildcard_fields = Map.get(all_denied_fields, "*", [])
    wildcard_key = hd(Regex.run(~r/([^\.]*)/u, event_name)) <> ".*"

    wildcard_fields ++
      Map.get(all_denied_fields, wildcard_key, []) ++ Map.get(all_denied_fields, event_name, [])
  end
end
