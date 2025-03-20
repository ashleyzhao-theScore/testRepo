defmodule Marketplace.Page.EventLiveStream do
  @moduledoc """
  Event Live Stream representation
  """

  @type status :: :scheduled | :live

  @type t :: %__MODULE__{
          id: String.t(),
          igm_event_id: String.t(),
          status: status(),
          geo_allow: list(String.t()),
          geo_block: list(String.t())
        }

  defstruct [
    :id,
    :igm_event_id,
    :status,
    geo_allow: [],
    geo_block: []
  ]
end
