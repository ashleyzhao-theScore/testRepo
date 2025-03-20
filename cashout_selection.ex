defmodule Sportsbook.Cashout.CashoutSelection do
  @moduledoc """
  Describes a cashout selection
  """

  @type cashout_type ::
          :invalid
          # TODO: Remove abbreviated types when clients switch over
          | :pg_pg
          | :pg_ip
          | :ip_ip
          | :pregame_pregame
          | :pregame_inplay
          | :inplay_inplay
  @type t :: %__MODULE__{
          selection_id: String.t(),
          cashout_type: cashout_type(),
          full_cashout_type: cashout_type(),
          probability: float()
        }

  defstruct [
    :selection_id,
    :cashout_type,
    :full_cashout_type,
    :probability
  ]
end
