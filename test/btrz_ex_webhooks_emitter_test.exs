defmodule BtrzWebhooksEmitterTest do
  use ExUnit.Case

  test "emit webhook to test sqs" do
    message = %{
      "provider_id" => "123",
      "api_key" => "123",
      "data" => %{}
    }
    assert :ok == BtrzWebhooksEmitter.emit("test.event", message)
  end

end
