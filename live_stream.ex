defmodule Sportsbook.LiveStream.LiveStreams do
  @moduledoc """
  Contains all the shared logic needed for live streams
  """

  alias Sportsbook.Datadex
  alias Sportsbook.LiveStream.LiveStreamError
  alias Sportsbook.LiveStream.LiveStreamIGMError
  alias Sportsbook.LiveStream.LiveStreamResult
  alias Sportsbook.LiveStream.PatronRestriction
  alias Sportsbook.LiveStream.PatronRestrictions
  alias Sportsbook.LiveStream.PlayerLink
  alias Sportsbook.PatronData
  alias SportsbookProtobuf.LiveStream.LiveStreamProtobuf
  alias SportsbookHttp.Clients.LiveStream
  # credo:disable-for-next-line Credo.Check.Readability.AliasAs
  alias Sportsbook.Utils.Application, as: Utils
  alias ThescoreEx.Bet.RegionCodes

  require Logger

  @type customer_id :: String.t()

  @type live_stream_result ::
          PlayerLink.t() | PatronRestriction.t() | LiveStreamError.t() | LiveStreamIGMError.t()

  @doc """
  Retrieves a live stream from IGM if a patron is eligible
  """
  @spec get_live_stream(String.t(), PatronData.t(), String.t()) :: LiveStreamResult.t()
  def get_live_stream(vegas_event_id, patron_data, user_ip) do
    # Add in calls to the HTTP Clients to fetch live streams from IGM
    result =
      with {:ok, event} <- get_event(vegas_event_id),
           {:ok, :eligible} <-
             PatronRestrictions.patron_eligibility(
               patron_data,
               event.event_live_stream.geo_allow,
               event.event_live_stream.geo_block,
               vegas_event_id
             ),
           {:ok, live_stream} <- get_live_stream(vegas_event_id),
           {:ok, player_link} <-
             get_player_link(event, live_stream, patron_data.patron_id, user_ip) do
        player_link
      else
        %PatronRestriction{} = restriction ->
          restriction

        %LiveStreamIGMError{} = live_stream_igm_error ->
          live_stream_igm_error

        {:error, :event_not_found} ->
          Logger.error("#{__MODULE__}.live_stream event not found in datadex",
            vegas_event_id: vegas_event_id
          )

          LiveStreamError.new()

        {:error, :live_stream_not_found} ->
          Logger.error("#{__MODULE__}.live_stream live stream not found in datadex",
            vegas_event_id: vegas_event_id
          )

          LiveStreamError.new()

        {:error, :event_live_stream_nil} ->
          Logger.error("#{__MODULE__}.live_stream live stream is nil",
            vegas_event_id: vegas_event_id
          )

          LiveStreamError.new()

        {:error, reason} ->
          Logger.error("#{__MODULE__}.live_stream #{inspect(reason)}",
            vegas_event_id: vegas_event_id
          )

          LiveStreamError.new()
      end

    %LiveStreamResult{id: vegas_event_id, live_stream_result: result}
  end

  defp get_player_link(event, live_stream, patron_id, user_ip) do
    geo_allow = event.event_live_stream.geo_allow
    geo_block = event.event_live_stream.geo_block

    igm_event_id = live_stream.igm_event_id
    stream_name = live_stream.stream_name

    with {:ok, stream_link} <-
           LiveStream.get_live_stream_link(igm_event_id, stream_name, patron_id, user_ip),
         {:ok, player_link} <- LiveStream.get_player_link(stream_link["streamLink"], user_ip) do
      {:ok, PlayerLink.new(live_stream, stream_link, player_link)}
    else
      {:igm_error, status, body} ->
        Logger.error(
          "#{__MODULE__}.live_stream #{status} #{body["Message"] || body["message"]}",
          vegas_event_id: event.id,
          operation_code: body["OperationCode"],
          user_ip: user_ip,
          status_code: status,
          igm_event_id: igm_event_id,
          jurisdiction: RegionCodes.active_region()
        )

        case {status, body["OperationCode"]} do
          {_, 306} -> PatronRestriction.new(:out_of_region, geo_allow, geo_block)
          {_, 402} -> LiveStreamIGMError.new(:event_pending)
          {_, 403} -> LiveStreamIGMError.new(:event_closed)
          {_, 404} -> LiveStreamIGMError.new(:event_cancelled)
          {429, _} -> LiveStreamIGMError.new(:rate_limited)
          _ -> LiveStreamIGMError.new(:error)
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp get_event(event_id) do
    case Datadex.get(:events, event_id) do
      nil -> {:error, :event_not_found}
      %{event_live_stream: nil} -> {:error, :event_live_stream_nil}
      event -> {:ok, event}
    end
  end

  defp get_live_stream(event_id) do
    case Datadex.list(:event_live_streams, :by_event_id, event_id: event_id) do
      [] -> {:error, :live_stream_not_found}
      live_streams -> {:ok, live_streams |> List.first() |> LiveStreamProtobuf.from_protobuf()}
    end
  end

  @doc """
  Retrieves the customer_id for sending to IGM.
  Only "tsb" and "espnbet" are supported
  """
  @spec get_customer_id() ::
          {:ok, customer_id()} | {:error, :unsupported_application}
  def get_customer_id do
    case Utils.application() do
      "tsb" ->
        {:ok,
         Application.fetch_env!(:sportsbook, LiveStream)[
           :espn_igm_api_customer_id
         ]}

      "espnbet" ->
        {:ok,
         Application.fetch_env!(:sportsbook, LiveStream)[
           :espn_igm_api_customer_id
         ]}

      application ->
        Logger.error("#{__MODULE__}.get_customer_id #{application} not supported")
        {:error, :unsupported_application}
    end
  end

  @doc """
  Retrieves the homepage for sending to IGM's redirectUrl.
  Only "tsb" and "espnbet" are supported.
  The redirect url does not seem to be doing anything but this is required in the query params
  """
  @spec get_home_page_url() ::
          {:ok, String.t()} | {:error, :unsupported_application}
  def get_home_page_url do
    case Utils.application() do
      "tsb" ->
        {:ok, "https://thescore.bet"}

      "espnbet" ->
        {:ok, "https://espnbet.com"}

      application ->
        Logger.error("#{__MODULE__}.get_home_page_url #{application} not supported")
        {:error, :unsupported_application}
    end
  end

  @doc """
  Gets the base url by the path
  """
  @spec get_base_path_by_query(String.t()) :: String.t()
  def get_base_path_by_query("liveStream" <> _path),
    do: Application.fetch_env!(:sportsbook, SportsbookHttp.Clients.LiveStream)[:base_player_url]

  def get_base_path_by_query(_path),
    do: Application.fetch_env!(:sportsbook, SportsbookHttp.Clients.LiveStream)[:base_url]
end
