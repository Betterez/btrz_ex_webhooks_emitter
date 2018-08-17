defmodule BtrzWebhooksEmitterTest do
  use ExUnit.Case

  describe("emit/2") do
    test "won't emit event if event_name is not binary" do
      message = %{
        "api_key" => "123",
        "provider_id" => "123",
        "data" => %{}
      }

      assert :error == BtrzWebhooksEmitter.emit(:myevent, message)
    end

    test "won't emit event if provider_id is missing" do
      message = %{
        "api_key" => "123",
        "data" => %{}
      }

      assert :error == BtrzWebhooksEmitter.emit("test.event", message)
    end

    test "won't emit event if api_key is missing" do
      message = %{
        "provider_id" => "123",
        "data" => %{}
      }

      assert :error == BtrzWebhooksEmitter.emit("test.event", message)
    end

    test "emit webhook to test sqs" do
      message = %{
        "provider_id" => "123",
        "api_key" => "123",
        "data" => %{}
      }

      assert :ok == BtrzWebhooksEmitter.emit("test.event", message)
    end
  end

  describe("build_message/2") do
    test "build_message with the correct fields" do
      message = %{
        "provider_id" => "123",
        "api_key" => "123",
        "data" => %{"hi" => "you"}
      }

      built = Poison.decode!(BtrzWebhooksEmitter.build_message("test.event", message))
      assert built["event"] == "test.event"

      assert built["id"] =~
               ~r/^[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/i

      assert is_binary(built["ts"]) == true
      assert built["apiKey"] == message["api_key"]
      assert built["providerId"] == message["provider_id"]
      assert built["data"] == %{"hi" => "you"}
    end

    test "build_message using optional url" do
      message = %{
        "provider_id" => "123",
        "api_key" => "123",
        "data" => %{"hi" => "you"},
        "url" => "https://pretty.url/"
      }

      built = Poison.decode!(BtrzWebhooksEmitter.build_message("test.event", message))
      assert built["event"] == "test.event"

      assert built["id"] =~
               ~r/^[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/i

      assert is_binary(built["ts"]) == true
      assert built["apiKey"] == message["api_key"]
      assert built["providerId"] == message["provider_id"]
      assert built["data"] == %{"hi" => "you"}
      assert built["url"] == message["url"]
    end

    test "build_message using a denied field" do
      message = %{
        "provider_id" => "123",
        "api_key" => "123",
        "data" => %{"password" => "secret"}
      }

      built = Poison.decode!(BtrzWebhooksEmitter.build_message("test.event", message))
      assert built["data"] == %{}
    end

    test "build_message using denied fields with multiple wildcards" do
      message = %{
        "provider_id" => "123",
        "api_key" => "123",
        "data" => %{"password" => "secret", "credentials" => %{}}
      }

      built = Poison.decode!(BtrzWebhooksEmitter.build_message("customer.created", message))
      assert built["data"] == %{}
    end
  end
end
