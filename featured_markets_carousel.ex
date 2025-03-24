defmodule Marketplace.Page.FeaturedMarketsCarousel do
  @moduledoc """
  Represents a carousel with featured markets.
  """

  alias Marketplace.Page.ComponentQueryConfig
  alias Marketplace.Page.EventQueryConfig
  alias Thescore.Sportsbook.Page.V1.FeaturedBetLocation

  defstruct [:id, :label, :deep_link, :component_query_config, :event_query_config, :location]

  @type t :: %__MODULE__{
          id: String.t(),
          label: String.t() | nil,
          deep_link: Sportsbook.DeepLink.t() | nil,
          component_query_config: ComponentQueryConfig.t() | nil,
          event_query_config: EventQueryConfig.t() | nil,
          location: FeaturedBetLocation.t() | nil
        }
end
