defmodule Affirm.ResponseTest do
  use ExUnit.Case
  alias Affirm.Response

  test "new/1 parses response containing type" do
    response_struct = %{type: "test"} |> Response.new()
    assert response_struct.type == "test"
  end

  test "new/1 can respond to nil or empty map" do
    response_struct = Response.new(nil)
    assert is_nil(response_struct.type)

    response_struct = Response.new(%{})
    assert is_nil(response_struct.type)
  end

  test "new/1 parses response containing events list, amount and charge_id" do
    event_list = [
      %{
        created: "2014-03-20T14:00:33Z",
        currency: "USD",
        id: "UI1ZOXSXQ44QUXQL",
        transaction_id: "TpR3Xrx8TkvuGio0",
        type: "auth"
      }
    ]

    response_struct = %{id: "sdhglksdgh", amount: "6000", events: event_list, order_id: "garbage"} |> Response.new()
    assert response_struct.type == "auth"
    refute is_nil(response_struct.charge_id)
    refute is_nil(response_struct.amount)
  end

  test "new/1 returns empty Response struct when type or event attr does not exist" do
    response_struct = %{flim: "test"} |> Response.new()
    assert is_nil(response_struct.type)
  end
end
