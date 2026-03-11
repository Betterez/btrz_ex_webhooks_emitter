defmodule BtrzWebhooksEmitter.Compression do
  @moduledoc """
  Compresses the webhook message `data` field for SQS.
  Supports gzip (via :zlib) and zstd (via :ezstd).
  """

  @valid_algos MapSet.new(["zstd", "gzip"])

  @doc """
  Returns the compression algorithm from WEBHOOK_COMPRESS env, or nil.
  Valid values: "zstd", "gzip" (case-insensitive). Any other value or missing -> nil.
  """
  @spec get_compress_algo() :: nil | binary
  def get_compress_algo do
    case System.get_env("WEBHOOK_COMPRESS") do
      nil ->
        nil

      v when is_binary(v) ->
        normalized = String.downcase(String.trim(v))
        if MapSet.member?(@valid_algos, normalized), do: normalized, else: nil
    end
  end

  @doc """
  Compresses `data_map` (map) with the given algorithm ("zstd" or "gzip").
  Returns base64-encoded string.
  """
  @spec compress(map, binary) :: binary
  def compress(data_map, algo) when algo in ["zstd", "gzip"] do
    json = Poison.encode!(data_map)
    raw = compress_raw(json, algo)
    Base.encode64(raw)
  end

  defp compress_raw(payload, "gzip"), do: :zlib.gzip(payload)

  defp compress_raw(payload, "zstd"), do: :ezstd.compress(payload)
end
