defmodule Sportsbook.Betslip.BetslipHeartbeat do
  @moduledoc """
    Heartbeat server for betslips. When active, sends a heartbeat GRPC request at configurable interval, defaults 5 seconds

    Monitors its parent when being started, and gracefully exits when its parent exits

    Options:

    - caller <pid>: The PID of the calling process. Used to monitor and gracefully exit when parent dies
    - patron_data: <PatronData>: Patron data to be passed to the GRPC call
    - request_data: <map>: RequestData to be passed to the GRPC call
  """

  use GenServer
  use ThescoreEx.Bet.Configurable, config_key: :sportsbook

  alias SportsbookGrpc.Clients.Concierge.BetslipStreamClient

  @impl GenServer
  @spec init(map()) :: {:ok, map()}
  def init(opts \\ %{}) do
    unless opts[:skip_monitoring], do: Process.monitor(opts.caller)

    send(self(), :heartbeat)

    opts
    |> schedule_heartbeat()
    |> then(&{:ok, &1})
  end

  @impl GenServer
  def handle_info(:heartbeat, %{patron_data: patron_data, request_data: request_data} = state) do
    if state[:dummy] do
      apply(state[:dummy], [state[:caller]])
    else
      {:ok, _ref} = BetslipStreamClient.heartbeat(patron_data, request_data)
    end

    state
    |> schedule_heartbeat()
    |> then(&{:noreply, &1})
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, _pid, reason}, state) do
    {:stop, reason, state}
  end

  defp schedule_heartbeat(state) do
    timer_ref = Process.send_after(self(), :heartbeat, app_config(:interval))
    Map.put(state, :timer, timer_ref)
  end
end
