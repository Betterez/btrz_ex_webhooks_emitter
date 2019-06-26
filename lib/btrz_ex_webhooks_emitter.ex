defmodule BtrzWebhooksEmitter do
  @moduledoc """
  BtrzWebhooksEmitter emits webhooks to SQS for the Betterez platform.

  This module has the API to send messages asynchrounously to the `BtrzWebhooksEmitter.SQS`.

  You will have to set these ENV vars:

  * AWS_SERVICE_KEY
  * AWS_SERVICE_SECRET
  * SQS_QUEUE_NAME

  You can set `SQS_QUEUE_NAME` in your config:
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

  @sqs_server :btrz_webhooks_emitter_sqs

  @doc """
  Builds and sends messages asynchrounously to the BtrzWebhooksEmitter.SQS
  If there is a validation error in your `attrs` it will return `:error` and log the error, otherwise always `:ok`.
  """
  @spec emit(binary, map) :: :ok | :error
  def emit(event_name, attrs) do
    case validate_and_build_message(event_name, attrs) do
      {:ok, message} ->
        BtrzWebhooksEmitter.SQS.emit(@sqs_server, message)

      {:error, reason} ->
        Logger.error("cannot emit: #{inspect(reason)}")
        :error
    end
  end

  @doc """
  Builds and sends messages synchrounously to the BtrzWebhooksEmitter.SQS
  For particular use, try always to use emit/2 if possible.

  Returns `{:ok, term}` or `{:error, term}`
  """
  @spec emit_sync(binary, map) :: BtrzWebhooksEmitter.SQS.emit_sync_response()
  def emit_sync(event_name, attrs) do
    case validate_and_build_message(event_name, attrs) do
      {:ok, message} ->
        BtrzWebhooksEmitter.SQS.emit_sync(@sqs_server, message)

      {:error, reason} ->
        Logger.error("cannot emit: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc false
  @spec validate_and_build_message(binary, map) :: {:ok, map} | {:error, any}
  defp validate_and_build_message(event_name, attrs) do
    with :ok <- validate_fields(event_name, attrs),
         true <- service_started?(@sqs_server),
         message <- build_message(event_name, attrs) do
      {:ok, message}
    else
      {:error, reason} ->
        {:error, reason}

      false ->
        {:error, "BtrzWebhooksEmitter.SQS GenServer is down"}

      e ->
        {:error, e}
    end
  end

  @doc false
  @spec validate_fields(binary, map) :: :ok | {:error, String.t()}
  defp validate_fields(event_name, _attrs) when not is_binary(event_name) do
    {:error, "event_name is missing"}
  end

  defp validate_fields(_event_name, attrs) do
    cond do
      not is_binary(attrs["provider_id"]) ->
        {:error, "provider_id is missing"}

      not is_binary(attrs["api_key"]) ->
        {:error, "api_key is missing"}

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
  Returns the message map.
  """
  @spec build_message(binary, map) :: map
  def build_message(event_name, attrs) do
    %{
      id: UUID.uuid4(),
      ts: DateTime.utc_now() |> DateTime.to_unix(:millisecond),
      providerId: attrs["provider_id"],
      apiKey: attrs["api_key"],
      event: event_name,
      data: filter_fields(event_name, attrs["data"])
    }
    |> maybe_put_url(attrs)
  end

  @doc false
  defp maybe_put_url(message, %{"url" => url}) do
    Map.put_new(message, :url, url)
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
