defmodule Affirm.Response do
  @moduledoc """
  Affirm defines all of the useful response data points in their API. This module
  houses a struct of those and provides a function for building the struct
  given a response map.
  """

  @type t :: %__MODULE__{
    amount:         pos_integer,
    charge_id:      String.t,
    created:        String.t,
    currency:       String.t,
    fee:            String.t,
    fee_refunded:   String.t,
    id:             String.t,
    order_id:       String.t,
    transaction_id: String.t,
    type:           String.t,
    message:        String.t,
    status:         String.t,
    events:         list(map)
  }

  defstruct [
    amount:         nil,
    charge_id:      nil,
    created:        nil,
    currency:       nil,
    fee:            nil,
    fee_refunded:   nil,
    id:             nil,
    order_id:       nil,
    transaction_id: nil,
    type:           nil,
    message:        nil,
    status:         nil,
    events:         nil
  ]

  @doc """
  Function builds a response object based on parsed json return map
  send back from Affirm.
  """
  @spec new(map, boolean) :: t
  def new(response, is_transactional \\ true)
  def new(%{events: events, amount: amount, id: charge_id, order_id: order_id}, true) do
    events
    |> hd
    |> new
    |> dump_into_struct(%{amount: amount, charge_id: charge_id, order_id: order_id})
  end
  def new(nil, _), do: %__MODULE__{}
  def new(response, _) do
    case Enum.empty?(response) do
      false -> %__MODULE__{} |> dump_into_struct(response)
      _     -> %__MODULE__{}
    end
  end

  @spec dump_into_struct(struct, map) :: t
  defp dump_into_struct(mod, map_response) do
    Enum.reduce Map.keys(map_response), mod, fn (atom, acc) ->
      value = Map.get(map_response, atom)
      verify_atom =
        case is_binary(atom) do
          true -> String.to_atom(atom)
          _    -> atom
        end

      Map.put(acc, verify_atom, value)
    end
  end
end
