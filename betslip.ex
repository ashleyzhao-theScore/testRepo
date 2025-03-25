defmodule Sportsbook.Betslip do
  @moduledoc """
  Betslip representation and from_protobuf converter
  """
  alias Sportsbook.Betslip.BetslipError
  alias Sportsbook.Betslip.Parlay
  alias Sportsbook.Betslip.RoundRobin
  alias Sportsbook.Betslip.Straight
  alias Sportsbook.Betslip.Teaser

  alias Marketplace.Page.MarketSelection
  alias Marketplace.Page.MarketSelectionMetadata

  @type t :: %__MODULE__{
          id: String.t(),
          patron_id: String.t(),
          straight: Straight.t(),
          parlay: Parlay.t(),
          round_robin: RoundRobin.t(),
          teaser: Teaser.t(),
          market_selections: list(MarketSelection.t()),
          number_of_selections: integer(),
          generated_at: DateTime.t(),
          errors: list(BetslipError.t()),
          market_selections_metadata: list(MarketSelectionMetadata.t()),
          retail_session_id: String.t() | nil
        }

  defstruct [
    :id,
    :patron_id,
    :straight,
    :parlay,
    :round_robin,
    :teaser,
    :market_selections,
    :errors,
    :number_of_selections,
    :generated_at,
    :retail_session_id,
    market_selections_metadata: []
  ]
end
