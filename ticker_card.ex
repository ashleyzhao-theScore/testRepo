defmodule Marketplace.Page.TickerCard do
  @moduledoc """
  A TickerCard struct
  """
  alias Marketplace.Page.Event
  alias Marketplace.Page.Market
  alias Marketplace.Page.MarketComponent
  alias Marketplace.Page.ComponentQueryConfig

  defstruct [
    :id,
    :fallback_event,
    :icon_url,
    :component_query_config,
    :market_components,
    :markets,
    :favoured_alignment
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          fallback_event: Event.t(),
          icon_url: String.t() | nil,
          component_query_config: ComponentQueryConfig.t(),
          markets: [Market.t()] | nil,
          market_components: [MarketComponent.t()],
          favoured_alignment: :away | :home | nil
        }

  @doc """
  Creates a new TickerCard
  """
  @spec new(list(Event.t()) | Event.t(), ComponentQueryConfig.t(), map()) :: t() | list(t())

  def new(events, component_query_config, icon_url_map) when is_list(events) do
    Enum.map(events, fn event ->
      new(event, component_query_config, icon_url_map)
    end)
  end

  def new(fallback_event, component_query_config, icon_url_map) do
    %__MODULE__{
      id: fallback_event.id,
      icon_url: Map.get(icon_url_map, Event.maybe_get_sport_slug(fallback_event), nil),
      fallback_event: fallback_event,
      component_query_config: component_query_config,
      markets: nil,
      market_components: [],
      favoured_alignment: nil
    }
  end
end
