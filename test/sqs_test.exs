defmodule BtrzWebhooksEmitter.SQSTest do
  use ExUnit.Case, async: true

  @sqs_server :btrz_webhooks_emitter_sqs

  describe "with a wrong queue_url" do
    setup do
      child_spec = %{
        id: :sqs_emitter,
        start:
          {BtrzWebhooksEmitter.SQS, :start_link,
           [[queue: "http://wrong_url"], [name: :sqs_emitter]]}
      }

      sqs_emitter = start_supervised!(child_spec)
      %{sqs_emitter: sqs_emitter}
    end

    test "emit async will return :ok afterall", %{sqs_emitter: sqs_emitter} do
      message = %{
        "providerId" => "123",
        "event" => "something_ocurred!",
        "apiKey" => "123",
        "data" => %{}
      }

      assert :ok = BtrzWebhooksEmitter.SQS.emit(sqs_emitter, message)
    end

    test "emit sync will return error", %{sqs_emitter: sqs_emitter} do
      message = %{
        "providerId" => "123",
        "event" => "something_ocurred!",
        "apiKey" => "123",
        "data" => %{}
      }

      assert {:error, {:http_error, 404, %{}}} =
               BtrzWebhooksEmitter.SQS.emit_sync(sqs_emitter, message)
    end
  end

  describe "SQS GenServer client" do
    test "emit will emit async and return :ok" do
      message = %{
        "providerId" => "123",
        "event" => "something_ocurred!",
        "apiKey" => "123",
        "data" => %{}
      }

      assert :ok == BtrzWebhooksEmitter.SQS.emit(@sqs_server, message)
    end

    test "emit_sync will emit sync and return {:ok, result}" do
      message = %{
        "providerId" => "123",
        "event" => "something_ocurred!",
        "apiKey" => "123",
        "data" => %{}
      }

      assert {:ok, %{status_code: 200}} = BtrzWebhooksEmitter.SQS.emit_sync(@sqs_server, message)
    end
  end
end
