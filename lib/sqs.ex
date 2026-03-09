defmodule BtrzWebhooksEmitter.SQS do
  @moduledoc """
  Genserver for emitting events to the configured AWS SQS

  If there is no `SQS_QUEUE_NAME`, the GenServer will be started with `:ignore` and the process will exit normally.
  """
  use GenServer
  require Logger

  @typedoc """
  Response for every function
  """
  @type emit_sync_response :: {:ok, term} | {:error, term}

  @doc """
  Starts a new BtrzWebhooksEmitter process.
  """
  def start_link(aws_config, opts \\ []) do
    GenServer.start_link(__MODULE__, aws_config, opts)
  end

  @doc """
  Emits messages asynchrounously
  Returns always `:ok`
  """
  @spec emit(GenServer.server(), map) :: :ok
  def emit(server, message) do
    GenServer.cast(server, {:emit, Poison.encode!(message)})
  end

  @doc """
  Emits messages asynchrounously to a specific queue URL.
  The `opts` keyword list supports `:queue_url` to override the default queue.
  Returns always `:ok`
  """
  @spec emit(GenServer.server(), map, keyword()) :: :ok
  def emit(server, message, opts) do
    GenServer.cast(server, {:emit, Poison.encode!(message), opts})
  end

  @doc """
  Emits messages synchrounously
  For particular use, try always to use emit/2 if possible.
  Returns `emit_sync_response :: {:ok, term} | {:error, term}`
  """
  @spec emit_sync(GenServer.server(), map) :: emit_sync_response
  def emit_sync(server, message) do
    GenServer.call(server, {:emit, Poison.encode!(message)})
  end

  @doc """
  Emits messages synchrounously to a specific queue URL.
  The `opts` keyword list supports `:queue_url` to override the default queue.
  Returns `emit_sync_response :: {:ok, term} | {:error, term}`
  """
  @spec emit_sync(GenServer.server(), map, keyword()) :: emit_sync_response
  def emit_sync(server, message, opts) do
    GenServer.call(server, {:emit, Poison.encode!(message), opts})
  end

  # Callbacks

  def init(nil) do
    Logger.error("missing queue url - ignoring BtrzWebhooksEmitter.SQS GenServer: exit normally")
    :ignore
  end

  def init(aws_config) do
    state = %{
      aws_config: aws_config
    }

    {:ok, state}
  end

  @doc """
  Sends async the message to AWS SQS.
  If something fails, it will just log the error.
  """
  def handle_cast({:emit, message}, state) do
    case send_message(state.aws_config, message) do
      {:error, reason} ->
        Logger.error("#{inspect(reason)}")

      {:ok, _} ->
        Logger.info("webhook emited! #{inspect(Poison.decode!(message))}")
    end

    {:noreply, state}
  end

  def handle_cast({:emit, message, opts}, state) do
    config = maybe_override_queue(state.aws_config, opts)

    case send_message(config, message) do
      {:error, reason} ->
        Logger.error("#{inspect(reason)}")

      {:ok, _} ->
        Logger.info("webhook emited! #{inspect(Poison.decode!(message))}")
    end

    {:noreply, state}
  end

  @doc """
  Sends sync the message to AWS SQS and returns {:ok, result}.
  If something fails, it will log the error and returns {:error, reason}
  """
  def handle_call({:emit, message}, _from, state) do
    result =
      case send_message(state.aws_config, message) do
        {:error, reason} ->
          Logger.error("#{inspect(reason)}")
          {:error, reason}

        {:ok, result} ->
          Logger.info("webhook emited! #{inspect(Poison.decode!(message))}")
          {:ok, result}
      end

    {:reply, result, state}
  end

  def handle_call({:emit, message, opts}, _from, state) do
    config = maybe_override_queue(state.aws_config, opts)

    result =
      case send_message(config, message) do
        {:error, reason} ->
          Logger.error("#{inspect(reason)}")
          {:error, reason}

        {:ok, result} ->
          Logger.info("webhook emited! #{inspect(Poison.decode!(message))}")
          {:ok, result}
      end

    {:reply, result, state}
  end

  defp maybe_override_queue(aws_config, opts) do
    case Keyword.get(opts, :queue_url) do
      nil -> aws_config
      queue_url -> Keyword.put(aws_config, :queue, queue_url)
    end
  end

  defp send_message(aws_config, message) do
    operation =
      ExAws.SQS.send_message(
        aws_config[:queue],
        message
      )

    request_fn =
      Application.get_env(:btrz_ex_webhooks_emitter, :ex_aws_request_fn, &ExAws.request/2)

    request_fn.(operation, aws_config)
  end
end
