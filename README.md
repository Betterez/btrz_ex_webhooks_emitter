# BtrzWebhooksEmitter

Betterez elixir client for emitting webhooks to the SQS queue.

## Documentation
API documentation at HexDocs [https://hexdocs.pm/btrz_ex_webhooks_emitter](https://hexdocs.pm/btrz_ex_webhooks_emitter)

## Installation

```elixir
def deps do
  [{:btrz_ex_webhooks_emitter, "~> 0.2.0"}]
end
```
## Configuration
This lib will use the following ENV variables:
  * AWS_ACCESS_KEY_ID
  * AWS_SECRET_ACCESS_KEY
  * SQS_QUEUE_NAME (or by config)

Or you can set `SQS_QUEUE_NAME` in your config:
```elixir
config :btrz_ex_webhooks_emitter, queue_url: "id/name"
```
## How to use
```elixir
message = %{
  "provider_id" => "123",
  "api_key" => "PROVIDER_PUBLIC_KEY",
  "data" => %{"foo" => "bar"}
}
BtrzWebhooksEmitter.emit("transaction.created", message)
```

`BtrzWebhooksEmitter.emit/2` will send asynchronously a message to SQS always responding `:ok`, it will log an error if exists.

## Synchronous mode
You might want to use `BtrzWebhooksEmitter.emit_sync/2` to send synchronously a message to SQS returning `{:ok, result}`, or in case of error will log and return `{:error, reason}`.

## Denied fields
`btrz-webhooks-denied-fields` library will be consumed to filter off the possible denied fields.
 
## Test
`AWS_ACCESS_KEY_ID=YOUR_KEY AWS_SERVICE_SECRET=YOUR_SECRET_KEY SQS_QUEUE_URL=YOUR_QUEUE_URL mix test`


