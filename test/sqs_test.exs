defmodule BtrzWebhooksEmitter.SQSTest do
  use ExUnit.Case

  test "handle_cast emit" do
    state = %{queue: Application.get_env(:btrz_ex_webhooks_emitter, :queue_url)}

    message =
      Poison.encode!(%{
        "providerId" => "123",
        "event" => "something_ocurred!",
        "apiKey" => "123",
        "data" => %{}
      })

    assert {:noreply, state} == BtrzWebhooksEmitter.SQS.handle_cast({:emit, message}, state)
  end
end
