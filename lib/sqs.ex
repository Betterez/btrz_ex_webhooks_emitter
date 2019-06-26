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
  Emits messages synchrounously
  For particular use, try always to use emit/1 if possible.
  Returns `emit_sync_response :: {:ok, term} | {:error, term}`
  """
  @spec emit_sync(GenServer.server(), map) :: emit_sync_response
  def emit_sync(server, message) do
    GenServer.call(server, {:emit, Poison.encode!(message)})
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

  defp send_message(aws_config, message) do
    ExAws.SQS.send_message(
      aws_config[:queue],
      message
    )
    |> ExAws.request(aws_config)
  end
end
