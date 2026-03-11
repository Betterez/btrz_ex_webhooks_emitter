defmodule BtrzWebhooksEmitterTest do
  use ExUnit.Case

  describe("emit/2") do
    test "won't emit event if event_name is not binary" do
      message = %{
        "provider_id" => "123",
        "data" => %{}
      }

      assert :error == BtrzWebhooksEmitter.emit(:myevent, message)
    end

    test "won't emit event if provider_id is missing" do
      message = %{
        "data" => %{}
      }

      assert :error == BtrzWebhooksEmitter.emit("test.event", message)
    end

    test "emit webhook to test sqs" do
      message = %{
        "provider_id" => "123",
        "data" => %{}
      }

      assert :ok == BtrzWebhooksEmitter.emit("test.event", message)
    end
  end

  describe("emit_sync/2") do
    test "won't emit event if event_name is not binary" do
      message = %{
        "provider_id" => "123",
        "data" => %{}
      }

      assert {:error, _} = BtrzWebhooksEmitter.emit_sync(:myevent, message)
    end

    test "won't emit event if provider_id is missing" do
      message = %{
        "data" => %{}
      }

      assert {:error, _} = BtrzWebhooksEmitter.emit_sync("test.event", message)
    end

    test "emit webhook to test sqs" do
      message = %{
        "provider_id" => "123",
        "data" => %{}
      }

      assert {:ok, _} = BtrzWebhooksEmitter.emit_sync("test.event", message)
    end
  end

  describe("build_message/2") do
    test "build_message with the correct fields" do
      message = %{
        "provider_id" => "123",
        "data" => %{"hi" => "you"}
      }

      built = BtrzWebhooksEmitter.build_message("test.event", message)
      assert built.event == "test.event"

      assert built.id =~
               ~r/^[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/i

      assert is_integer(built.ts) == true
      assert built.providerId == message["provider_id"]
      assert built.data == %{"hi" => "you"}
    end

    test "build_message using optional url" do
      message = %{
        "provider_id" => "123",
        "data" => %{"hi" => "you"},
        "url" => "https://pretty.url/"
      }

      built = BtrzWebhooksEmitter.build_message("test.event", message)
      assert built.event == "test.event"

      assert built.id =~
               ~r/^[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/i

      assert is_integer(built.ts) == true
      assert built.providerId == message["provider_id"]
      assert built.data == %{"hi" => "you"}
      assert built.url == message["url"]
    end

    test "build_message using a denied field" do
      message = %{
        "provider_id" => "123",
        "data" => %{"password" => "secret"}
      }

      built = BtrzWebhooksEmitter.build_message("test.event", message)
      assert built.data == %{}
    end

    test "build_message using denied fields with multiple wildcards" do
      message = %{
        "provider_id" => "123",
        "data" => %{"password" => "secret", "credentials" => %{}}
      }

      built = BtrzWebhooksEmitter.build_message("customer.created", message)
      assert built.data == %{}
    end
  end

  describe "build_message/2 WEBHOOK_COMPRESS" do
    @key "WEBHOOK_COMPRESS"

    setup do
      original = System.get_env(@key)

      on_exit(fn ->
        if original, do: System.put_env(@key, original), else: System.delete_env(@key)
      end)

      :ok
    end

    test "when unset, message has no enc and data is map" do
      System.delete_env(@key)
      message = %{"provider_id" => "123", "data" => %{"foo" => "bar"}}
      built = BtrzWebhooksEmitter.build_message("test.event", message)
      refute Map.has_key?(built, :enc)
      assert built.data == %{"foo" => "bar"}
    end

    @tag :skip
    test "when WEBHOOK_COMPRESS=zstd, message has enc zstd and data is base64" do
      System.put_env(@key, "zstd")
      message = %{"provider_id" => "123", "data" => %{"foo" => "bar", "nested" => %{"a" => 1}}}
      built = BtrzWebhooksEmitter.build_message("test.event", message)
      assert built.enc == "zstd"
      assert is_binary(built.data)

      decoded = built.data |> Base.decode64!() |> :ezstd.decompress() |> Poison.decode!()

      assert decoded == %{"foo" => "bar", "nested" => %{"a" => 1}}
    end

    test "when WEBHOOK_COMPRESS=gzip, message has enc gzip and data is base64" do
      System.put_env(@key, "gzip")
      message = %{"provider_id" => "123", "data" => %{"foo" => "bar"}}
      built = BtrzWebhooksEmitter.build_message("test.event", message)
      assert built.enc == "gzip"
      assert is_binary(built.data)
      decoded = built.data |> Base.decode64!() |> :zlib.gunzip() |> Poison.decode!()
      assert decoded == %{"foo" => "bar"}
    end

    test "when WEBHOOK_COMPRESS is invalid, no enc and data is map" do
      System.put_env(@key, "br")
      message = %{"provider_id" => "123", "data" => %{"foo" => "bar"}}
      built = BtrzWebhooksEmitter.build_message("test.event", message)
      refute Map.has_key?(built, :enc)
      assert built.data == %{"foo" => "bar"}
    end

    @tag :skip
    test "when WEBHOOK_COMPRESS=ZSTD (case insensitive), enc is zstd" do
      System.put_env(@key, "ZSTD")
      message = %{"provider_id" => "123", "data" => %{"x" => 1}}
      built = BtrzWebhooksEmitter.build_message("test.event", message)
      assert built.enc == "zstd"

      decoded = built.data |> Base.decode64!() |> :ezstd.decompress() |> Poison.decode!()

      assert decoded == %{"x" => 1}
    end
  end
end
